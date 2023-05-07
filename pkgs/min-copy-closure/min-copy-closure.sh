#!/usr/bin/env bash

target_host=$1
shift

paths=$(nix-store -q --requisites "$@")
needed=""

coproc remote {
    ssh -C ${target_host}
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
