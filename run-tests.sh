#!/usr/bin/env bash

export DEVICE=${DEVICE-qemu}
export TMPDIR=${TMPDIR-/tmp}

for i in tests/*/run.sh; do
    echo $i
    $i || exit 1
done
