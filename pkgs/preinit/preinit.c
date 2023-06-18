#ifdef PREINIT_USE_LIBC
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <string.h>
#else
#include <nolibc.h>
#endif
#include <asm/setup.h>

#define ERR(x) write(2, x, strlen(x))
#define AVER(c) do { if(c < 0) ERR("failed: "  #c); } while(0)

static int begins_with(char * str, char * prefix)
{
	while(*prefix) {
		if(*str == '\0') return 0;
		if(*str != *prefix) return 0;
		str++;
		prefix++;
	}
	return 1;
}

static void fork_exec(char * command, char *args[])
{
	int fork_pid = fork();
	AVER(fork_pid);
	if(fork_pid > 0)
		wait(NULL);
	else
		AVER(execve(command, args, NULL));
}

char banner[]  = "Running pre-init...\n";
char buf[COMMAND_LINE_SIZE];

int main(int argc, char *argv[], char *envp[])
{
        asm("la $gp, _gp\nsw $gp,16($sp)");
	char *rootdevice = 0;
	char *p = buf;
	write(1, banner, strlen(banner));

	mount("none", "/proc", "proc", 0, NULL);

	int cmdline = open("/proc/cmdline", O_RDONLY, 0);

	if(cmdline>=0) {
		int len = read(cmdline, buf, sizeof buf - 1);
		buf[len]='\0';
		write(1, "cmdline ", 8);
		write(1, buf, len);
	};

	while(*p) {
		if(begins_with(p, "root=")) {
			rootdevice = p + 5;
			while(*p && (*p != ' ')) p++;
			*p= '\0';
		}
		while(*p && (*p != ' ')) p++;
		p++;
	}

	if(rootdevice) {
		write(1, "rootdevice ", 11);
		write(1, rootdevice, strlen(rootdevice));
		write(1, "\n", 1);

		AVER(mount(rootdevice, "/target/persist", "jffs2", 0, NULL));
		AVER(mount("/target/persist/nix", "/target/nix",
			   "bind", MS_BIND, NULL));

		char *exec_args[] = { "activate",  "/target" };
		fork_exec("/target/persist/activate", exec_args);
		AVER(chdir("/target"));

		AVER(mount("/target", "/", "bind", MS_BIND | MS_REC, NULL));
		AVER(chroot(".")); 
		argv[0] = "init";
		argv[1] = NULL;

		AVER(execve("/persist/init", argv, envp));
	}
}
