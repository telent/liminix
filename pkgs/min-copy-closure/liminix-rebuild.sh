#!/usr/bin/env bash

ssh_command=${SSH_COMMAND-ssh}

if [ "$1" = "--no-reboot" ] ; then
    reboot="true"
    shift
else
    reboot="reboot"
fi

target_host=$1
shift

if [ -z "$target_host" ] ; then
    echo Usage: liminix-rebuild \[--no-reboot\] target-host params
    exit 1
fi

if toplevel=$(nix-build "$@" -A outputs.systemConfiguration --no-out-link); then
    echo systemConfiguration $toplevel
    min-copy-closure $target_host $toplevel
    $ssh_command $target_host $toplevel/bin/install
    $ssh_command  $target_host "sync; source /etc/profile; reboot"
else
    echo Rebuild failed
fi
