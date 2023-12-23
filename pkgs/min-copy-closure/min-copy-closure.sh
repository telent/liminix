#!/usr/bin/env bash

ssh_command=${SSH_COMMAND-ssh}

root_prefix=/
verbose=true

while [[ $# -gt 0 ]]; do
    case $1 in
	-r|--root)
	    root_prefix="$2"
	    shift
	    shift
	    ;;
	-q|--quiet)
	    verbose=""
	    shift
	    ;;
	-*|--*)
	    echo "Unknown option $1"
	    exit 1
	    ;;
	*)
	    if test -z "$target_host"; then
		target_host="$1"
	    else
		paths+=("$1") # save positional arg
	    fi
	    shift # past argument
	    ;;
    esac
done

progress() {
    test -n "$verbose" && echo $*
}

if [ -z "$target_host" ] ; then
    echo Usage: min-copy-closure [--root /mnt] target-host paths
    exit 1
fi

if [ -z "$IN_NIX_BUILD" ] ; then
    # can't run nix-store in a derivation, so we have to
    # skip the requisites when running tests in hydra
    paths=$(nix-store -q --requisites "$paths")
fi
needed=""

coproc remote {
    ${ssh_command} -C -T ${target_host}
}

exec 10>&${remote[1]}

for p in $paths; do
    progress  -n Checking $(basename $p) ...
    echo "test -e ${root_prefix}$p && echo skip || echo $p"  >&10
    read n <&${remote[0]}
    case $n in
	skip)
	    progress skip
	    ;;
	*)
	    needed="${needed} $n"
	    progress will copy
	    ;;
    esac
done

if test -z "$needed" ; then
    echo Nothing to copy
    exit 1
fi

echo "cd ${root_prefix} && cpio -d -i >/dev/console"  >&10

find $needed | cpio  -H newc -o  >&10

# make sure the connection hasn't died
echo "echo finished"  >&10
read n <&${remote[0]}
echo $n
