#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

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

char * pr_u32(int32_t input) {
    static char buf[9];
    const char *digits = "0123456789abcdef";
    int i=0;

    buf[i] = digits[(input & 0xf0000000) >> 28];
    buf[i+1] = digits[(input & 0x0f000000) >> 24];
    if(buf[i] != '0' || buf[i+1] != '0') i+=2;

    buf[i] = digits[(input & 0x00f00000) >> 20];
    buf[i+1] = digits[(input & 0x000f0000) >> 16];
    if(buf[i] != '0' || buf[i+1] != '0') i+=2;

    buf[i] = digits[(input & 0x0000f000) >> 12];
    buf[i+1] = digits[(input & 0x00000f00) >> 8];
    if(buf[i] != '0' || buf[i+1] != '0') i+=2;

    buf[i] = digits[(input & 0x000000f0) >> 4];
    buf[i+1] = digits[(input & 0x0000000f)];
    i+=2;

    buf[i] ='\0';
    if(write(2, buf, i))
	return buf;
    else
	return NULL;
}


void parseopts(char * cmdline, char **root, char **rootfstype) {
    *root = 0;
    *rootfstype = 0;

    for(char *p = cmdline; *p; p++) {
	if(begins_with(p, "root=")) {
	    *root = p + strlen("root=");
	    while(*p && (*p != ' ')) p++;

	    if(*p) {
		*p = '\0';
		p++;
	    };
	};
	if(begins_with(p, "rootfstype=")) {
	    *rootfstype = p + strlen("rootfstype=");
	    while(*p && (*p != ' ')) p++;
	    if(*p) {
		*p = '\0';
		p++;
	    };
	};
    };
}

#ifdef TESTS
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

// cc -DTESTS  -o parseopts parseopts.c && ./parseopts

#define die(fmt, ...) do { printf(fmt, __VA_ARGS__); exit(1); } while(0)
#define S(x) #x
#define expect_equal(actual, expected) \
    if(!actual || strcmp(actual, expected)) die("%d: expected \"%s\", got \"%s\"", __LINE__, expected, actual);


int main()
{
    char * root = "/dev/hda1";
    char * rootfstype = "xiafs";
    char *buf;

    // finds root= and rootfstype= options
    buf = strdup("liminix console=ttyS0,115200 panic=10 oops=panic init=/bin/init loglevel=8 root=/dev/ubi0_4 rootfstype=ubifs fw_devlink=off mtdparts=phram0:18M(rootfs) phram.phram=phram0,0x40400000,18874368,65536 root=/dev/mtdblock0 foo");
    parseopts(buf, &root, &rootfstype);
    expect_equal(root, "/dev/mtdblock0");
    expect_equal(rootfstype, "ubifs");

    // in case of duplicates, chooses the latter
    // also: works if the option is end of string
    buf = strdup("liminix console=ttyS0,115200 panic=10 oops=panic init=/bin/init loglevel=8 root=/dev/ubi0_4 rootfstype=ubifs fw_devlink=off mtdparts=phram0:18M(rootfs) phram.phram=phram0,0x40400000,18874368,65536 root=/dev/mtdblock0");
    parseopts(buf, &root, &rootfstype);
    expect_equal(root, "/dev/mtdblock0");
    expect_equal(rootfstype, "ubifs");

    // options may appear in either order
    buf = strdup("liminix fw_devlink=off root=/dev/hda1 rootfstype=ubifs  foo");
    parseopts(buf, &root, &rootfstype);
    expect_equal(root, "/dev/hda1");
    expect_equal(rootfstype, "ubifs");

    buf = strdup("liminix rootfstype=ubifs fw_devlink=off root=/dev/hda1 foo");
    parseopts(buf, &root, &rootfstype);
    expect_equal(rootfstype, "ubifs");
    expect_equal(root, "/dev/hda1");

    // provides NULL for missing options
    buf = strdup("liminix rufustype=ubifs fw_devlink=off foot=/dev/hda1");
    parseopts(buf, &root, &rootfstype);
    if(rootfstype) die("expected null rootfstype, got \"%s\"", rootfstype);
    if(root) die("expected null root, got \"%s\"", root);

    // provides empty strings for empty options
    buf = strdup("liminix rootfstype= fw_devlink=off root= /dev/hda1");
    parseopts(buf, &root, &rootfstype);
    if(strlen(rootfstype)) die("expected empty rootfstype, got \"%s\"", rootfstype);
    if(strlen(root)) die("expected null root, got \"%s\"", root);

    expect_equal("01", pr_u32(1));
    expect_equal("ab", pr_u32(0xab));
    expect_equal("0abc", pr_u32(0xabc));
    expect_equal("aabc", pr_u32(0xaabc));
    expect_equal("deadcafe", pr_u32(0xdeadcafe));
}

#endif
