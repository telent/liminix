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

rootfs=$(mktemp mips-vm-fs-XXXXXX)
dd if=/dev/zero of=$rootfs bs=1M count=16 conv=sync
dd if=$2 of=$rootfs bs=65536 conv=sync,nocreat,notrunc

if test -n "$3"; then
    initramfs="-initrd $3"
fi


INIT=${INIT-/bin/init}
echo $QEMU_OPTIONS
qemu-system-mips \
    -M malta -m 256 \
    -echr 16 \
    -append "liminix default console=ttyS0,38400n8 panic=10 oops=panic init=$INIT loglevel=8 root=/dev/mtdblock0 block2mtd.block2mtd=/dev/vda,65536" \
    -drive file=$rootfs,format=raw,readonly=off,if=virtio,index=0 \
    ${initramfs} \
    -netdev socket,id=access,mcast=230.0.0.1:1234,localaddr=127.0.0.1 \
    -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=access,mac=ba:ad:1d:ea:21:02 \
    -netdev socket,id=lan,mcast=230.0.0.1:1235,localaddr=127.0.0.1 \
    -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=lan,mac=ba:ad:1d:ea:21:01 \
    -kernel $1 -display none $flags ${QEMU_OPTIONS}
