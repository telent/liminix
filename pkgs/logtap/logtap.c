#include <errno.h>                   // for errno
#include <fcntl.h>                   // for fcntl, O_NONBLOCK, open, F_GETFL
#include <poll.h>                    // for POLLERR, POLLHUP, POLLIN
#include <signal.h>                  // for signal, SIGPIPE, SIG_IGN
#include <stdarg.h>                  // for va_end, va_list, va_start
#include <stdio.h>                   // for fprintf, stderr, vfprintf
#include <stdlib.h>                  // for malloc, exit
#include <string.h>                  // for strlen, strcat, strcpy, strerror
#include <sys/stat.h>                // for stat, mkfifo, S_IFIFO
#include <unistd.h>                  // for write, STDOUT_FILENO, read

#define PROGRAM_NAME "logtap"

#ifdef _GNU_SOURCE
#include <error.h>
#else
#include <stdarg.h>
static void error(int status, int errnum, const char* fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);

    fprintf(stderr, PROGRAM_NAME ": ");
    vfprintf(stderr, fmt, ap);
    if (errnum)
        fprintf(stderr, ": %s", strerror(errnum));
    fprintf(stderr, "\n");
    va_end(ap);
    if (status)
        exit(status);
}
#endif

int open_shipper_fifo(char* pathname)
{
    int fd = -1;
    struct stat statbuf;

    if (stat(pathname, &statbuf)) {
        switch (errno) {
        case ENOENT:
            if(mkfifo(pathname, 0700)) {
                error(1, errno, "mkfifo %s failed", pathname);
            }
            break;
        default:
            error(1, errno, "stat %s failed", pathname);
            break;
        }
    } else {
        if (!(statbuf.st_mode & S_IFIFO)) {
            error(1, errno, "%s exists already and is not a fifo", pathname);
        }
    }
    if (fd < 0) {
        fd = open(pathname, O_NONBLOCK | O_RDWR, 0);
        if (fd < 0)
            error(1, errno, "failed to open fifo %s", pathname);
    };
    return fd;
}

struct pollfd fds[] = {
    { .fd = 0, .events = POLLIN },
    { .fd = 1, .events = POLLERR },
    { .fd = -1, .events = POLLERR },
};

#define FIFO_STATE_GOOD (-1)
#define FIFO_STATE_TIMEOUT_EXPIRED (0)
#define FIFO_STATE_TIMEOUT_MAX (50) /* ? probably going to depend on log volume */

char *start_cookie, *stop_cookie;
static int fifo_state = FIFO_STATE_TIMEOUT_EXPIRED;

int write_fifo(int fd, char* buf, int count)
{
    int written_bytes = 0;
    if (fifo_state == FIFO_STATE_GOOD) {
        written_bytes = write(fd, buf, count);
        if (written_bytes == -1) {
            fifo_state = FIFO_STATE_TIMEOUT_MAX;
            write(1, stop_cookie, strlen(stop_cookie));
        }
    } else if (fifo_state > 0) {
        fifo_state--;
    } else if (fifo_state == FIFO_STATE_TIMEOUT_EXPIRED) {
        written_bytes = write(fd, buf, count);
        if (written_bytes >= 0) {
            fifo_state = FIFO_STATE_GOOD;
            write(1, start_cookie, strlen(start_cookie));
        } else {
            fifo_state = FIFO_STATE_TIMEOUT_MAX;
            /* don't log again, we're in this state because it was bad
               already, and it's still bad */
        }
    } else {
        error(1, 0, "impossible(sic) fifo state %d", fifo_state);
    };

    /* if the fifo can't be written, pretend to caller that we wrote
       everything so that it doesn't back up. the backfill process
       will write these entries later when the shipper is online
       again */
    return (fifo_state == FIFO_STATE_GOOD) ? written_bytes : count;
}

#define WRITE_LITERAL(fd, c) write(fd, c, sizeof c)

int main(int argc, char* argv[])
{
    char* buf = malloc(8192);
    int out_bytes = 0;
    int fifo_bytes = 0;

    if (argc != 3) {
        error(1, 0, "usage: " PROGRAM_NAME " /path/to/fifo cookie-text");
    }
    char* fifo_pathname = argv[1];
    char* cookie = argv[2];
    start_cookie = malloc(strlen(cookie) + 8);
    stop_cookie = malloc(strlen(cookie) + 7);

    strcpy(start_cookie, cookie);
    strcat(start_cookie, " START\n");
    strcpy(stop_cookie, cookie);
    strcat(stop_cookie, " STOP\n");

    signal(SIGPIPE, SIG_IGN);

    fds[2].fd = open_shipper_fifo(fifo_pathname);

    int flags = fcntl(STDOUT_FILENO, F_GETFL);
    fcntl(STDOUT_FILENO, F_SETFL, flags | O_NONBLOCK);

    int quitting = 0;
    while (!quitting) {
        int nfds = poll(fds, 3, 2000);
        if (nfds > 0) {
            if ((fds[0].revents & (POLLIN | POLLHUP)) && (out_bytes == 0) && (fifo_bytes == 0)) {
                out_bytes = read(fds[0].fd, buf, 8192);
                if (out_bytes == 0) {
                    quitting = 1;
                    WRITE_LITERAL(1, PROGRAM_NAME " detected eof of file on stdin, exiting\n");
                };
                fifo_bytes = out_bytes;
            };

            if (fds[1].revents & (POLLERR | POLLHUP)) {
                exit(1); // can't even log an error if the logging stream fails
            };
            if (fds[2].revents & (POLLERR | POLLHUP)) {
                error(1, 0, "error or hangup writing to log fifo (revents=%d)", fds[2].revents);
            };

            if (out_bytes) {
                out_bytes -= write(fds[1].fd, buf, out_bytes);
            };
            if (fifo_bytes) {
                fifo_bytes -= write_fifo(fds[2].fd, buf, fifo_bytes);
            };
        } else {
            /* poll timed out, may as well try and see if the shipper
             * is alive again
             */
            if (fifo_state > FIFO_STATE_TIMEOUT_EXPIRED)
                fifo_state = FIFO_STATE_TIMEOUT_EXPIRED;
        };
    };
}
