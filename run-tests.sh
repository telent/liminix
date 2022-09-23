#!/usr/bin/env bash

export DEVICE=${DEVICE-qemu}
export TMPDIR=${TMPDIR-/tmp}

NIX_PATH=liminix=`pwd`:$NIX_PATH

for i in tests/*/run.sh; do
    echo $i
    (cd `dirname $i`; ./`basename $i` $* ) || exit 1
done
