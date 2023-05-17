#!/usr/bin/env bash

target_host=$1
shift

if [ -z "$target_host" ] ; then
    echo Usage: liminix-rebuild target-host params
    exit 1
fi

toplevel=$(nix-build "$@" -A outputs.systemConfiguration --no-out-link)
min-copy-closure $target_host $toplevel
ssh $target_host cp -P $toplevel/bin/\* /
ssh $target_host reboot
