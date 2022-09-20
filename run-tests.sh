#!/usr/bin/env bash

export TMPDIR=${TMPDIR-/tmp}
for i in tests/*/run.sh; do
    echo $i
    $i
done
