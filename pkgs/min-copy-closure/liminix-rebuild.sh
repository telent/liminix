#!/usr/bin/env bash

ssh_command=${SSH_COMMAND-ssh}

reboot="reboot"

case "$1" in
    "--no-reboot")
	unset reboot
	shift
	;;
    "--fast")
	reboot="soft"
	shift
	;;
esac

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
    case "$reboot" in
	reboot)
	    $ssh_command $target_host "sync; source /etc/profile; reboot"
	    ;;
	soft)
	    $ssh_command $target_host $toplevel/bin/restart-services
	    ;;
	*)
	    ;;
    esac
else
    echo Rebuild failed
fi
