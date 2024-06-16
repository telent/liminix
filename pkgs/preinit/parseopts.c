#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#include "opts.h"


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

static char *eat_word(char *p)
{
    while(*p && (*p != ' ')) p++;

    if(*p) {
	*p = '\0';
	p++;
    };
    return p;
}

static char * eat_param(char *p, char *param_name, char **out)
{
    if(begins_with(p, param_name)) {
	*out = p + strlen(param_name);
	p = eat_word(p);
    };
    return p;
}

void parseopts(char * cmdline, struct root_opts *opts) {
    for(char *p = cmdline; *p; p++) {
	p = eat_param(p, "root=", &(opts->device));
	p = eat_param(p, "rootfstype=", &(opts->fstype));
	p = eat_param(p, "rootflags=", &(opts->mount_opts));
	p = eat_param(p, "altroot=", &(opts->altdevice));
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
    struct root_opts opts = {
	.device = "/dev/hda1",
	.fstype = "xiafs",
	.mount_opts = NULL
    };
    char *buf;

    // finds root= rootfstype= rootflags= options
    buf = strdup("liminix console=ttyS0,115200 panic=10 oops=panic init=/bin/init loglevel=8 root=/dev/ubi0_4 rootfstype=ubifs rootflags=subvol=1 fw_devlink=off mtdparts=phram0:18M(rootfs) phram.phram=phram0,0x40400000,18874368,65536 root=/dev/mtdblock0 foo");
    memset(&opts, '\0', sizeof opts); parseopts(buf, &opts);
    expect_equal(opts.device, "/dev/mtdblock0");
    expect_equal(opts.fstype, "ubifs");
    expect_equal(opts.mount_opts, "subvol=1");

    // finds altroot= options
    buf = strdup("liminix console=ttyS0,115200 panic=10 oops=panic init=/bin/init loglevel=8 root=/dev/ubi0_4 rootfstype=ubifs rootflags=subvol=1 fw_devlink=off mtdparts=phram0:18M(rootfs) phram.phram=phram0,0x40400000,18874368,65536 root=/dev/mtdblock0 altroot=/dev/mtdblock6 foo");
    memset(&opts, '\0', sizeof opts); parseopts(buf, &opts);
    expect_equal(opts.device, "/dev/mtdblock0");
    expect_equal(opts.altdevice, "/dev/mtdblock6");
    expect_equal(opts.fstype, "ubifs");
    expect_equal(opts.mount_opts, "subvol=1");

    // in case of duplicates, chooses the latter
    // also: works if the option is end of string
    buf = strdup("liminix console=ttyS0,115200 panic=10 oops=panic init=/bin/init loglevel=8 root=/dev/ubi0_4 rootfstype=ubifs fw_devlink=off mtdparts=phram0:18M(rootfs) phram.phram=phram0,0x40400000,18874368,65536 root=/dev/mtdblock0");
    memset(&opts, '\0', sizeof opts); parseopts(buf, &opts);
    expect_equal(opts.device, "/dev/mtdblock0");
    expect_equal(opts.fstype, "ubifs");

    // options may appear in either order
    buf = strdup("liminix fw_devlink=off root=/dev/hda1 rootfstype=ubifs  foo");
    memset(&opts, '\0', sizeof opts); parseopts(buf, &opts);
    expect_equal(opts.device, "/dev/hda1");
    expect_equal(opts.fstype, "ubifs");

    // works when rootflags is the last option
    buf = strdup("liminix fw_devlink=off root=/dev/hda1 rootfstype=ubifs rootflags=subvol=@");
    memset(&opts, '\0', sizeof opts); parseopts(buf, &opts);
    expect_equal(opts.device, "/dev/hda1");
    expect_equal(opts.fstype, "ubifs");
    expect_equal(opts.mount_opts, "subvol=@");

    buf = strdup("liminix rootfstype=ubifs fw_devlink=off root=/dev/hda1 foo");
    memset(&opts, '\0', sizeof opts); parseopts(buf, &opts);
    expect_equal(opts.fstype, "ubifs");
    expect_equal(opts.device, "/dev/hda1");

    // provides NULL for missing options
    buf = strdup("liminix rufustype=ubifs fw_devlink=off foot=/dev/hda1");
    memset(&opts, '\0', sizeof opts);  parseopts(buf, &opts);

    if(opts.fstype) die("expected null rootfstype, got \"%s\"", opts.fstype);
    if(opts.device) die("expected null root, got \"%s\"", opts.device);
    if(opts.mount_opts) die("expected null mount_opts, got \"%s\"", opts.mount_opts);
    if(opts.altdevice) die("expected null altdevice, got \"%s\"", opts.altdevice);

    // provides empty strings for empty options
    buf = strdup("liminix rootfstype= fw_devlink=off root= altroot= /dev/hda1");
    memset(&opts, '\0', sizeof opts);  parseopts(buf, &opts);

    if(strlen(opts.fstype)) die("expected empty rootfstype, got \"%s\"", opts.fstype);
    if(strlen(opts.device)) die("expected empty root, got \"%s\"", opts.device);
    if(strlen(opts.altdevice)) die("expected empty altroot, got \"%s\"", opts.altdevice);

    expect_equal("01", pr_u32(1));
    expect_equal("ab", pr_u32(0xab));
    expect_equal("0abc", pr_u32(0xabc));
    expect_equal("aabc", pr_u32(0xaabc));
    expect_equal("deadcafe", pr_u32(0xdeadcafe));
}

#endif
