#!/usr/bin/env sh
cd /nix/store
while read f ; do
    test "$f" = "end" && break
    test -e $f || echo -n $f " "
done
mkdir -p /tmp/store
cd /tmp/store
cpio -i
