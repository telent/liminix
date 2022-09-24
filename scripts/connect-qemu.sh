#!/usr/bin/env sh
nix-shell -p socat --run "socat -,raw,echo=0,icanon=0,isig=0,icrnl=0,escape=0x0f    unix-connect:$1"
