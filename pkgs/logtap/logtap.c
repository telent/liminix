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
    va_end(ap);

    fprintf(stderr, "\n");
    if (status)
        exit(status);
}
#endif

#define FIFO_RETRY_TIMEOUT_MAX (50)

struct pollfd fds[] = {
    { .fd = 0, .events = POLLIN },
    { .fd = 1, .events = POLLERR },
    { .fd = -1, .events = POLLERR },
};

#define START_SENTINEL "# LOG-SHIPPING-START\n"
#define STOP_SENTINEL "# LOG-SHIPPING-STOP\n"

static int fifo_connected(void)
{
    return (fds[2].fd >= 0);
}

int fifo_retry_timeout = -1;

int open_shipper_fifo(char* pathname)
{
    struct stat statbuf;
    int fd;

    if (stat(pathname, &statbuf)) {
        switch (errno) {
        case ENOENT:
            if (mkfifo(pathname, 0700)) {
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

    fd = open(pathname, O_WRONLY | O_NONBLOCK, 0);
    if (fd >= 0) {
        fifo_retry_timeout = -1;
        /* write cookie to stdout so that the backfill process knows
         * we are now logging realtime
         */
        write(fds[1].fd, START_SENTINEL, sizeof START_SENTINEL);
    } else {
        fifo_retry_timeout = FIFO_RETRY_TIMEOUT_MAX;
    }

    return fd;
}

int main(int argc, char* argv[])
{

    char* buf = malloc(8192);
    int out_bytes = 0;
    int tee_bytes = 0;

    if (argc != 3) {
        error(1, 0, "usage: " PROGRAM_NAME " /path/to/fifo");
    }

    signal(SIGPIPE, SIG_IGN);

    int flags = fcntl(STDOUT_FILENO, F_GETFL);
    fcntl(STDOUT_FILENO, F_SETFL, flags | O_NONBLOCK);

    fds[2].fd = open_shipper_fifo(argv[1]);

    int quitting = 0;

    while (!quitting) {
        int nfds = poll(fds, 3, 2000);
        if (nfds > 0) {
            if (fds[1].revents & (POLLERR | POLLHUP)) {
                exit(1); // can't even log an error if the logging stream fails
            };
            if (fifo_connected() && (fds[2].revents & (POLLERR | POLLHUP))) {
                close(fds[2].fd);
                fds[2].fd = -1;
                tee_bytes = 0;
                /* FIXME: nonblocking write, if stdout is not ready
                 * we will lose the message */
                (void) write(1, STOP_SENTINEL, sizeof STOP_SENTINEL);
                fifo_retry_timeout = FIFO_RETRY_TIMEOUT_MAX;
            };

            if ((fds[0].revents & (POLLIN | POLLHUP)) && (out_bytes == 0) && (tee_bytes == 0)) {
                out_bytes = read(fds[0].fd, buf, 8192);
                if (out_bytes == 0) {
                    quitting = 1;
                    buf = PROGRAM_NAME " detected eof of file on stdin, exiting\n";
                    out_bytes = strlen(buf);
                };
                if (fifo_connected())
                    tee_bytes = out_bytes;
            };

            if (out_bytes) {
                out_bytes -= write(fds[1].fd, buf, out_bytes);
            };
            if (tee_bytes) {
                int written = write(fds[2].fd, buf, tee_bytes);
                if (written >= 0)
                    tee_bytes -= written;
            };
            if (out_bytes == 0 && fifo_retry_timeout > 0) {
                fifo_retry_timeout--;
                if (fifo_retry_timeout == 0) {
                    fds[2].fd = open_shipper_fifo(argv[1]);
                };
            };
        } else {
            if (!fifo_connected()) {
                fds[2].fd = open_shipper_fifo(argv[1]);
            }
        };
    };
}
