#!/usr/bin/env sh
/nix/store/ydwiiagdhczynh2lbqh418rglibv93rv-qemu-host-cpu-only-7.0.0/bin/qemu-kvm \
    -M q35  -display none \
    -m 1024 \
    -accel kvm \
    -daemonize \
    -serial unix:qemu-console,server,nowait  -monitor unix:qemu-monitor,server,nowait \
    -drive file=chr-7.5.img,format=raw,if=virtio \
    -netdev socket,id=access,mcast=230.0.0.1:1234 \
    -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=access,mac=ba:ad:1d:ea:11:02 \
    -netdev socket,id=world,mcast=230.0.0.1:1236 \
    -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=world,mac=ba:ad:1d:ea:11:01
