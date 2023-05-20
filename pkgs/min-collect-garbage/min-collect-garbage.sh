#!/bin/sh
test -f /persist/nix-store-paths || exit 1
(cd /nix/store && min-list-garbage /persist/nix-store-paths | xargs rm -r)
