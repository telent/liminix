#!/usr/bin/env sh

cleanup(){
    if test -e foo.pid && test -d /proc/`cat foo.pid` ; then
	echo "killing qemu"
	kill `cat foo.pid`
    fi
}
trap cleanup EXIT
fatal(){
    err=$?
    echo "FAIL: command $(eval echo $BASH_COMMAND) exited with code $err"
    exit $err
}
trap fatal ERR

NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-build '<liminix>' -I liminix-config=./configuration.nix --arg device "import <liminix/devices/qemu>" -A outputs.default $*



../../scripts/run-qemu.sh \
    --background foo.sock \
    result/vmlinux result/squashfs \

nix-shell -p expect --run "expect wait-for-wlan.expect"
