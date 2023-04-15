#include <sys/stat.h>
#include <unistd.h>
#include <sys/sysmacros.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>

void print_file(char * path, mode_t mode, char * text) {
  int fd = open(path, O_CREAT | O_WRONLY, mode);
  char *p, *nxt;
  char b[1];
  if(fd >=0) {
    p = text;
    while(nxt = strchr(p, '\\')) {
      char upper = nxt[2];
      char lower = nxt[3];
      upper = (upper>'9') ? ((upper | 32) - 'a' + 10) : (upper - '0');
      lower = (lower>'9') ? ((lower | 32) - 'a' + 10) : (lower - '0');
      b[0] = (upper << 4) + lower;
      write(fd, p, nxt-p);
      write(fd, b, 1);
      p=nxt+4;
    }
    write(fd, p, strlen(p));
    close(fd);
  }
}



#define PRINTFILE(path, mode, text) print_file(path, (mode_t) mode, text)
#define MKDIR(path, mode) mkdir(path, mode)
#define MKNOD_C(path, mode, major,minor) mknod(path, mode | S_IFCHR, makedev(major, minor))
#define MKNOD_B(path, mode, major,minor) mknod(path, mode | S_IFBLK, makedev(major, minor))
#define LN_S(target, path) (void)symlink(target, path)
#define LN(target, path) link(target, path)
#define MKNOD_P(path, mode) mkfifo(path, mode)
#define CHOWN(path, uid, gid) chown(path, uid, gid)
