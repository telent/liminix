#include <poll.h>
#include <sys/timerfd.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>

#define PROGRAM_NAME "logtap"

#ifdef _GNU_SOURCE
#include <error.h>
#else
#include <stdarg.h>
static void error(int status, int errnum, const char * fmt, ...) {
    va_list ap;
    va_start(ap, fmt);

    fprintf(stderr, PROGRAM_NAME  ": ");
    vfprintf(stderr, fmt, ap);
    if(errnum) fprintf(stderr, ": %s", strerror(errnum));
    fprintf(stderr, "\n");
    if(status) exit(status);
}
#endif


int open_shipper_socket(char *pathname) {
    int fd;
    static int fail_count = 0;

    struct sockaddr_un sa = {
	.sun_family = AF_LOCAL
    };
    strncpy(sa.sun_path, pathname, sizeof(sa.sun_path) - 1);

    fd = socket(AF_LOCAL, SOCK_STREAM, 0);
    if(fd >= 0) {
	if(connect(fd, (struct sockaddr *) &sa, sizeof sa)) {
	    if((fail_count % 30) == 0)
		printf(PROGRAM_NAME ": cannot connect socket \"%s\": %s\n",
		       pathname,
		       strerror(errno));

	    fail_count++;
	    close(fd);
	    return -1;
	}
	int flags = fcntl(fd, F_GETFL);
	fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    }
    return fd;
}

struct pollfd fds[] = {
    { .fd = 0, .events = POLLIN },
    { .fd = 1, .events = POLLERR },
    { .fd = -1, .events = POLLERR },
};

int is_connected(void) {
    return (fds[2].fd >= 0);
}


int main(int argc, char * argv[]) {

    char * buf = malloc(8192);
    int out_bytes = 0;
    int tee_bytes = 0;

    if(argc != 3) {
	error(1, 0, "usage: " PROGRAM_NAME " /path/to/socket cookie-text");
    }
    char * socket_pathname = argv[1];
    char * cookie = argv[2];
    char * start_cookie = malloc(strlen(cookie) + 8);
    char * stop_cookie = malloc(strlen(cookie) + 7);

    if(strlen(socket_pathname) > 108) {
	error(1, 0, "socket pathname \"%s\" is too long, max 108 bytes",
	      socket_pathname);
    };

    strcpy(start_cookie, cookie); strcat(start_cookie, " START\n");
    strcpy(stop_cookie, cookie); strcat(stop_cookie, " STOP\n");

    signal(SIGPIPE, SIG_IGN);

    int flags = fcntl(STDOUT_FILENO, F_GETFL);
    fcntl(STDOUT_FILENO, F_SETFL, flags | O_NONBLOCK);

    int quitting = 0;
    while(! quitting) {
	int nfds = poll(fds, 3, 2000);
	if(nfds > 0) {
	    if((fds[0].revents & (POLLIN|POLLHUP)) &&
	       (out_bytes == 0) &&
	       (tee_bytes == 0)) {
		out_bytes = read(fds[0].fd, buf, 8192);
		if(out_bytes == 0) {
		    quitting = 1;
		    buf = PROGRAM_NAME " detected eof of file on stdin, exiting\n";
		    out_bytes = strlen(buf);
		};
		if(is_connected()) tee_bytes = out_bytes;
	    };

	    if(out_bytes) {
		out_bytes -= write(fds[1].fd, buf, out_bytes);
	    };
	    if(fds[1].revents & (POLLERR|POLLHUP)) {
		exit(1); // can't even log an error if the logging stream fails
	    };
	    if(is_connected()) {
		if(tee_bytes) {
		    tee_bytes -= write(fds[2].fd, buf, tee_bytes);
		};
		if(fds[2].revents & (POLLERR|POLLHUP)) {
		    close(fds[2].fd);
		    fds[2].fd = -1;
		    (void) write(1, stop_cookie, strlen(stop_cookie));
		};
	    };
	} else {
	    if(! is_connected()) {
		fds[2].fd = open_shipper_socket(argv[1]);
		if(is_connected()) {
		    /* write cookie to stdout so that the backfill
		     * process knows we are now logging realtime
		     */
		    write(fds[1].fd, start_cookie, strlen(start_cookie));
		}
	    }
	};
    };
}
