#!/usr/bin/env sh
set -e

statedir=$(mktemp -d)

cleanup(){
    test -n "$statedir" && test -d $statedir &&  rm  -rf $statedir
}
trap 'exit 1' INT HUP QUIT TERM ALRM USR1
trap 'cleanup' EXIT

(set -a; . ./test.env ; SERVICE_STATE=$statedir fennelrepl odhcp6-script.fnl ppp0 bound)  10>&1

(cd $statedir && find . -type f | xargs grep '' | sort) > actual
diff -u expected actual
cmp expected actual
