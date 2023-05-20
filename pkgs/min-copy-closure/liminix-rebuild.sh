#!/usr/bin/env bash

ssh_command=${SSH_COMMAND-ssh}
target_host=$1
shift

if [ -z "$target_host" ] ; then
    echo Usage: liminix-rebuild target-host params
    exit 1
fi

if toplevel=$(nix-build "$@" -A outputs.systemConfiguration --no-out-link); then
    echo systemConfiguration $toplevel
    min-copy-closure $target_host $toplevel
    $ssh_command $target_host cp -v -fP $toplevel/bin/* $toplevel/etc/* /persist
    $ssh_command  $target_host "sync; source /etc/profile; reboot"
else
    echo Rebuild failed
fi
