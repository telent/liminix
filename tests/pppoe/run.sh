#!/usr/bin/env sh


set -e

cleanup(){
    echo "do cleanup";
}
trap cleanup EXIT
trap 'echo "command $(eval echo $BASH_COMMAND) failed with exit code $?"; exit $?' ERR

NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-build '<liminix>' -I liminix-config=./configuration.nix --arg device "import <liminix/devices/qemu.nix>" -A outputs.default $*


if ! ( echo "cont" | socat -   unix-connect:../support/ppp-server/qemu-monitor); then
    echo "need pppoe server running"
    exit 1
fi

../../scripts/run-qemu.sh result/vmlinux result/squashfs
