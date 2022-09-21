# Liminix

A Nix-based system for configuring consumer wifi routers.

## What is this?

This is a Nix-based collection of software tailored for domestic wifi
router or IoT device devices, of the kind that OpenWrt or DD-WRT or
Gargoyle or Tomato run on. It's a reboot/restart/rewrite of NixWRT.

This is not NixOS-on-your-router: it's aimed at devices that are
underpowered for the full NixOS experience. It uses busybox tools,
musl instead of GNU libc, and s6-rc instead of systemd.

The Liminix name comes from Liminis, in Latin the genitive declension
of "limen", or "of the threshold". Your router stands at the threshold
of your (online) home and everything you send to/receive from the
outside word goes across it.


## Building

These instructions assume you have nixpkgs checked out in a peer
directory of this one.

You need a `configuration.nix` file pointed to by `<liminix-config>`, a
hardware device definition as argument `device`, and to choose an
appropriate output attribute depending on what your device is and how
you plan to install onto it. For example:

    NIX_PATH=nixpkgs=../nixpkgs:$NIX_PATH NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-build -I liminix-config=./tests/smoke/configuration.nix --arg device "import ./devices/qemu.nix" -A outputs.default

`outputs.default` is intended to do something appropriate for the
device, whatever that is. For the qemu device, it creates a directory
containing a squashfs root image and a kernel, with which you could
then run

    ./run-qemu.sh result/vmlinux result/squashfs


## Running tests

Assuming you have nixpkgs checked out in a peer directory of this one,

    NIX_PATH=nixpkgs=../nixpkgs:$NIX_PATH ./run-tests.sh


## Articles of interest

* [Build Safety of Software in 28 Popular Home Routers](https://cyber-itl.org/assets/papers/2018/build_safety_of_software_in_28_popular_home_routers.pdf):
   "of the access points and routers we reviewed, not a single one
took full advantage of the basic application armoring features
provided by the operating system. Indeed, only one or two models even
came close, and no brand did well consistently across all models
tested"
