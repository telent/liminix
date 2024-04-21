#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

#include <asm/setup.h>		/* for COMMAND_LINE_SIZE */

#include "opts.h"

#define ERR(x) write(2, x, strlen(x))
#define AVER(c) do { if(c < 0) { ERR("failed: "  #c ": error=0x" ); pr_u32(errno); ERR ( " - "); ERR(strerror(errno)); ERR("\n"); } } while(0)

char * pr_u32(int32_t input);

static void die() {
    /* if init exits, it causes a kernel panic. On the Turris
     * Omnia (and maybe other hardware, I don't know), the kernel
     * panics _before_ any of the messages from AVER are printed,
     * which makes it really hard to tell what went wrong.  So
     * let's wait a little here to give the console a chance to
     * catch up.
     *
     * Yes, I know that file descriptor IO is supposedly
     * non-buffered. Empirical observation suggests that there
     * must be a buffer of some kind somewhere though.
     */

    sleep(10);
    exit(1);
}

static int fork_exec(char * command, char *args[])
{
    int fork_pid = fork();
    AVER(fork_pid);
    if(fork_pid > 0)
	return wait(NULL);
    else
	return execve(command, args, NULL);
}

char banner[]  = "Running pre-init...\n";
char buf[COMMAND_LINE_SIZE];

int main(int argc, char *argv[], char *envp[])
{
    struct root_opts opts = {
	.device = NULL,
	.fstype = NULL,
	.mount_opts = NULL
    };

    write(1, banner, strlen(banner));

    AVER(mount("none", "/proc", "proc", 0, NULL));
    AVER(mount("none", "/dev", "devtmpfs", 0, NULL));

    int cmdline = open("/proc/cmdline", O_RDONLY, 0);

    if(cmdline>=0) {
	int len = read(cmdline, buf, sizeof buf - 1);
	buf[len]='\0';
	while(buf[len-1]=='\n') {
	    buf[len-1]='\0';
	    len--;
	}
	write(1, "cmdline: \"", 10);
	write(1, buf, len);
	write(1, "\"\n", 2);
    } else {
	ERR("failed: open(\"/proc/cmdline\")\n");
	die();
    }
    parseopts(buf, &opts);

    if(opts.device) {
	if(!opts.fstype) opts.fstype = "jffs2"; /* backward compatibility */
	write(1, "rootdevice ", 11);
	write(1, opts.device, strlen(opts.device));
	write(1, " (", 2);
	write(1, opts.fstype, strlen(opts.fstype));
	if(opts.mount_opts) {
	    write(1, ", opts=", 7);
	    write(1, opts.mount_opts, strlen(opts.mount_opts));
	}
	if(opts.altdevice) {
	    write(1, ", altdevice=", 12);
	    write(1, opts.altdevice, strlen(opts.altdevice));
	}
	write(1, ")\n", 2);

	if(!opts.altdevice) {
	    AVER(mount(opts.device, "/target/persist", opts.fstype, 0, opts.mount_opts));
	} else {
	    if(mount(opts.device, "/target/persist", opts.fstype, 0, opts.mount_opts) < 0) {
		AVER(mount(opts.altdevice, "/target/persist", opts.fstype, 0, opts.mount_opts));
	    }
	}

	// FUTUREWORK: any failure using `opts.device` should force us to consider rerunning this with the alternative rootfs.
	AVER(mount("/target/persist/nix", "/target/nix",
		   "bind", MS_BIND, NULL));

	char *exec_args[] = { "activate",  "/target", NULL };
	AVER(fork_exec("/target/persist/activate", exec_args));
	AVER(chdir("/target"));

	AVER(mount("/target", "/", "bind", MS_BIND | MS_REC, NULL));
	AVER(chroot("."));

	argv[0] = "init";
	argv[1] = NULL;

	AVER(execve("/persist/init", argv, envp));
    }
    die();
}
