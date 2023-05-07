#!/usr/bin/env bash

ssh_command=${SSH_COMMAND-ssh}
target_host=$1
shift

if [ -z "$target_host" ] ; then
    echo Usage: min-copy-closure target-host paths
    exit 1
fi

if [ -n "$IN_NIX_BUILD" ] ; then
    # can't run nix-store in a derivation, so we have to
    # skip the requisites when running tests in hydra
    paths=$@
else
    paths=$(nix-store -q --requisites "$@")
fi
needed=""

coproc remote {
    ${ssh_command} -C -T ${target_host}
}

exec 10>&${remote[1]}

for p in $paths; do
    echo -n Checking $(basename $p) ...
    echo "test -e $p && echo skip || echo $p"  >&10
    read n <&${remote[0]}
    case $n in
	skip)
	    echo skip
	    ;;
	*)
	    needed="${needed} $n"
	    echo will copy
	    ;;
    esac
done

if test -z "$needed" ; then
    echo Nothing to copy
    exit 1
fi

echo "cd / && cpio -v -i >/dev/console"  >&10

find $needed | cpio -H newc -o  >&10

echo "date"  >&10
read n <&${remote[0]}
echo $n
