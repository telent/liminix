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

void parseopts(char * cmdline, char **root, char **rootfstype);

#define ERR(x) write(2, x, strlen(x))
#define AVER(c) do { if(c < 0) ERR("failed: "  #c); } while(0)

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
    char *rootdevice = 0;
    char *rootfstype = 0;

    write(1, banner, strlen(banner));

    mount("none", "/proc", "proc", 0, NULL);

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
    };

    parseopts(buf, &rootdevice, &rootfstype);
	
    if(rootdevice) {
	if(!rootfstype) rootfstype = "jffs2"; /* backward compatibility */
	write(1, "rootdevice ", 11);
	write(1, rootdevice, strlen(rootdevice));
	write(1, " (", 2);
	write(1, rootfstype, strlen(rootfstype));
	write(1, ")\n", 1);

	AVER(mount(rootdevice, "/target/persist", rootfstype, 0, NULL));
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
}
