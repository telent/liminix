#!/usr/bin/env nix-shell
#! nix-shell -i bash -p qemu

if test "$1" = "--background" ; then
    socket=$2
    pid="`dirname $socket`/`basename $socket .sock`.pid"
    echo "running in background, socket is $socket, pid $pid"
    flags="--daemonize --pidfile $pid -chardev socket,id=sock,path=$2,server=on,wait=off,mux=on -mon chardev=sock,mode=readline -serial chardev:sock  "
    shift;shift
else
    flags="-serial mon:stdio"
fi

INIT=${INIT-/bin/init}

qemu-system-mips \
    -M malta -m 256 \
    -echr 16 \
    -append "default console=ttyS0,38400n8 panic=10 oops=panic init=$INIT loglevel=8 root=/dev/vda" \
    -drive file=$2,format=raw,readonly=on,if=virtio \
    -netdev socket,id=access,mcast=230.0.0.1:1234 \
    -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=access,mac=ba:ad:1d:ea:21:02 \
    -netdev socket,id=lan,mcast=230.0.0.1:1235 \
    -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=lan,mac=ba:ad:1d:ea:21:01 \
    -kernel $1 -display none $flags
