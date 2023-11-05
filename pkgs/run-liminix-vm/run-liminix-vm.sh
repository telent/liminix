#!/usr/bin/env bash

cleanup(){
    test -n "$rootfs" && test -f $rootfs && rm $rootfs
}
trap 'exit 1' INT HUP QUIT TERM ALRM USR1
trap 'cleanup' EXIT

usage(){
    echo "usage: $(basename $0) [--background /path/to/state_directory] kernel rootimg [initramfs]"
    echo -e "\nWithout --background, use C-p c (not C-a c) to switch to the monitor"
    exit 1
}

arch="mips"
if test "$1" = "--arch" ; then
    arch=$2
    shift;shift
fi

if test "$1" = "--background" ; then
    statedir=$2
    if test -z "$statedir" || ! test -d $statedir ; then
	usage
    fi
    pid="${statedir}/pid"
    socket="${statedir}/console"
    monitor="${statedir}/monitor"
    echo "running in background, socket is $socket, pid $pid"
    flags="--daemonize --pidfile $pid -serial unix:$socket,server,nowait -monitor unix:$monitor,server,nowait"
    shift;shift
else
    flags="-serial mon:stdio"
fi

test -n "$2" || usage

lan=${LAN-"socket,mcast=230.0.0.1:1235,localaddr=127.0.0.1"}

rootfs=$(mktemp run-liminix-vm-fs-XXXXXX)
dd if=/dev/zero of=$rootfs bs=1M count=16 conv=sync
dd if=$2 of=$rootfs bs=65536 conv=sync,nocreat,notrunc

if test -n "$3"; then
    initramfs="-initrd $3"
fi

case "$arch" in
    mips)
	QEMU="qemu-system-mips -M malta"
	;;
    aarch64)
	QEMU="qemu-system-aarch64 -M virt -semihosting -cpu cortex-a72"
	;;
    arm)
	# https://bugs.launchpad.net/qemu/+bug/1790975
	QEMU="qemu-system-arm -M virt,highmem=off -cpu cortex-a15"
	;;
    *)
	echo "unrecognised arch $arch"
	exit 1;
	;;
esac

phram="mtdparts=phram0:16M(rootfs) phram.phram=phram0,${PHRAM_ADDRESS},16Mi,65536 root=/dev/mtdblock0";

set -x
$QEMU \
    -m 272 \
    -echr 16 \
    -append "$CMDLINE liminix $phram" \
    -device loader,file=$rootfs,addr=$PHRAM_ADDRESS \
    ${initramfs} \
    -netdev socket,id=access,mcast=230.0.0.1:1234,localaddr=127.0.0.1 \
    -device virtio-net,disable-legacy=on,disable-modern=off,netdev=access,mac=ba:ad:1d:ea:21:02 \
    -netdev ${lan},id=lan \
    -device virtio-net,disable-legacy=on,disable-modern=off,netdev=lan,mac=ba:ad:1d:ea:21:01 \
    -kernel $1 -display none $flags ${QEMU_OPTIONS}
