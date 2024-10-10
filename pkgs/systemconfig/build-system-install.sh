#!/usr/bin/env bash

# this shell script can be run on the build system to
# min-copy-closure the system configuration onto the device
# and reboot/restart services as requested

die() {
    echo "$@"
    exit 1
}

# add min-copy-closure to the path. removing junk characters
# inserted by default.nix (q.v.)
min_copy_closure=@min-copy-closure@; PATH=${min_copy_closure//_/}/bin:$PATH

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

test -n "$target_host" || \
    die "Usage: $0 [--no-reboot] [--fast] target-host"

toplevel=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && readlink `pwd` )
test -e $toplevel/etc/nix-store-paths || die "missing etc/nix-store-paths, is this really a system configuration?"
echo installing from systemConfiguration $toplevel to host $target_host

min-copy-closure $target_host $toplevel
set -x
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
