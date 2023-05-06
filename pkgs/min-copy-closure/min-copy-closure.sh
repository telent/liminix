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
    echo "test -e $p && echo skip || echo $p"  >&10
    read n <&${remote[0]}
    case $n in
	skip)
	    :
	    ;;
	*)
	    needed="${needed} $n"
	    echo Will copy $n
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
