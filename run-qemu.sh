#!/usr/bin/env nix-shell
#! nix-shell -i bash -p qemu

qemu-system-mips \
    -M malta -m 256 \
    -append "earlyprintk=serial,ttyS0 console=ttyS0,38400n8 panic=10 oops=panic init=/bin/init loglevel=8 root=/dev/vda" \
    -drive file=$2,format=raw,readonly,if=virtio \
    -kernel $1  -nographic -display none -serial mon:stdio
