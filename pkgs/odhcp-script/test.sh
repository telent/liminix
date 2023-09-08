#!/usr/bin/env sh
set -e

statedir=$(mktemp -d)

cleanup(){
    test -n "$statedir" && test -d $statedir &&  rm  -rf $statedir
}
trap 'exit 1' INT HUP QUIT TERM ALRM USR1
trap 'cleanup' EXIT

# call the script twice with different state, to test that it cleans
# out old values when it runs again

(set -a; .  ./test.env ; ADDRESSES=2001:80:111:111:0:fff:123:567/128,3600,7200 SERVICE_STATE=$statedir fennelrepl odhcp6-script.fnl ppp0 bound)  10>&1

(set -a; . ./test.env ; SERVICE_STATE=$statedir fennelrepl odhcp6-script.fnl ppp0 bound)  10>&1

(cd $statedir && find . -type f | xargs grep '' | sort) > actual
diff -u expected actual
cmp expected actual
