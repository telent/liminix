#!/usr/bin/env bash

usage(){
    echo "usage: $(basename $0) [--background /path/to/state_directory] kernel rootimg"
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


INIT=${INIT-/bin/init}
echo $QEMU_OPTIONS
qemu-system-mips \
    -M malta -m 256 \
    -echr 16 \
    -append "liminix default console=ttyS0,38400n8 panic=10 oops=panic init=$INIT loglevel=8 root=/dev/vda" \
    -drive file=$2,format=raw,readonly=on,if=virtio \
    -netdev socket,id=access,mcast=230.0.0.1:1234,localaddr=127.0.0.1 \
    -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=access,mac=ba:ad:1d:ea:21:02 \
    -netdev socket,id=lan,mcast=230.0.0.1:1235,localaddr=127.0.0.1 \
    -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=lan,mac=ba:ad:1d:ea:21:01 \
    -kernel $1 -display none $flags ${QEMU_OPTIONS}
