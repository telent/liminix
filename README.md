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

### What about NixWRT?

This is an in-progress rewrite of NixWRT, incorporating Lessons
Learned. That said, as of today (September 2022) it is not yet
anywhere _near_ feature parity.

Liminix will eventually provide these differentiators over NixWRT:

* a writable filesystem so that software updates or reconfiguration
  (e.g. changing passwords) don't require taking the device offline to
  reflash it.

* more flexible service management with dependencies, to allow
  configurations such as "route through PPPoE if it is healthy, with
  fallback to LTE"

* a spec for valid configuration options (a la NixOS module options)
  to that we can detect errors at evaluation time instead of producing
  a bad image.

* a network-based mechanism for secrets management so that changes can
  be pushed from a central location to several Liminix devices at once

* send device metrics and logs to a monitoring/alerting/o11y
  infrastructure

Today though, it does approximately none of these things and certainly
not on real hardware.


## Building

### For the device

These instructions assume you have nixpkgs checked out in a peer
directory of this one.

You need a `configuration.nix` file pointed to by `<liminix-config>`, a
hardware device definition as argument `device`, and to choose an
appropriate output attribute depending on what your device is and how
you plan to install onto it. For example:

    NIX_PATH=nixpkgs=../nixpkgs:$NIX_PATH NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-build -I liminix-config=./tests/smoke/configuration.nix --arg device "import ./devices/qemu" -A outputs.default

`outputs.default` is intended to do something appropriate for the
device, whatever that is. For the qemu device, it creates a directory
containing a squashfs root image and a kernel.

### For the build machine

Liminix also includes some tools intended for the build machine. You can
run

    nix-shell -A buildEnv --arg device '(import ./devices/qemu)'

to get a shell environment with (currently) a tftp server and
a script to start a PPPoE server in QEMU for testing against.


#### QEMU

QEMU is useful for developing userland without needing to keep
flashing or messing with U-Boot: it also enables testing against
emulated network peers using [QEMU socket networking](https://wiki.qemu.org/Documentation/Networking#Socket),
which may be preferable to letting Liminix loose on your actual LAN.

We observe these conventions for QEMU network sockets, so that we can
run multiple emulated instances and have them wired up to each other
in the right way

* multicast 230.0.0.1:1234  : access (interconnect between router and "isp")
* multicast 230.0.0.1:1235  : lan
* multicast 230.0.0.1:1236  : world (the internet)

### Running Liminix in Qemu

`./scripts/run-qemu.sh` accepts a kernel vmlinux image and a squashfs
and runs qemu with appropriate config for two ethernet interfaces
hooked up to "lan" and "access" respectively. It connects the Liminix serial console
and the [QEMU monitor](https://www.qemu.org/docs/master/system/monitor.html) to
stdin/stdout. Use ^P (not ^A) to switch to the monitor.

If you run with `--background /path/to/unix/socket` it will fork into
the background and open a Unix socket at that pathname to communicate
on. Use `./scripts/connect-qemu.sh` to connect to it, and ^O to
disconnect.

### Emulated upstream connection

In the tests/support/ppp-server directory there is a derivation
to install and configure [Mikrotik RouterOS](https://mikrotik.com/software) as
a PPPoE access concentrator connected to the `access` and `world`
networks, so that Liminix PPPoE client support can be tested.

This is made available in the `buildEnv`, so you can do something like

    mkdir ros-sockets
    nix-shell -A buildEnv --arg device '(import ./devices/qemu)' \
	 --run ros-sockets
	./scripts/connect-qemu.sh ./ros-sockets/console

to start it and connect to it.

_Liminix does not provide RouterOS licences and it is your own
responsibility if you use this to ensure you're compliant with the
terms of Mikrotik's licencing._It may be supplemented or replaced in
time with configuurations for RP-PPPoE and/or Accel PPP.

## Running tests

Assuming you have nixpkgs checked out in a peer directory of this one,
you can run all of the tests by evaluating `ci.nix`:

    nix-build --argstr liminix `pwd`  --argstr nixpkgs `pwd`/../nixpkgs  --argstr unstable `pwd`/../unstable-nixpkgs/ ci.nix


Some of the tests require the emulated upstream connection to be running.

## Hardware

How you get the thing onto hardware will vary according to the device,
but is likely to involve U-Boot and TFTP.

There is a rudimentary TFTP server bundled with the system which runs
from the command line, has an allowlist for client connections, and
follows symlinks, so you can have your device download images direct
from the `./result` directory without exposing `/nix/store/` to the
internet or mucking about copying files to `/tftproot`. If the
permitted device is to be given the IP address 192.168.8.251 you might
do something like this:

    nix-shell -A buildEnv --arg device '(import ./devices/qemu)' \
	 --run "tufted -a 192.168.8.251 result"


## Troubleshooting

### Diagnosing unexpectedly large images

Sometimes you can add a package and it causes the image size to balloon
because it has dependencies on other things you didn't know about. Build the
`outputs.manifest` attribute, which is a json representation of the
filesystem, and you can run `nix-store --query` on it.

    NIX_PATH=nixpkgs=../nixpkgs:$NIX_PATH nix-build -I liminix-config=path/to/your/configuration.nix --arg device "import ./devices/qemu" -A outputs.manifest -o manifest
    nix-store -q --tree manifest


## Contributing

Contributions are welcome, though in these early days there may be a
bit of back and forth involved before patches are merged.  Have a read
of [CONTRIBUTING](CONTRIBUTING.md) and [STYLE](STYLE.md) and try to
intuit the unarticulated vision :-)

Liminix' primary repo is https://gti.telent.net/dan/liminix. There's a
[mirror on Github](https://github.com/telent/liminix) for convenience
and visibility: you can open PRs against that but be aware that the
process of merging them may be arcane. Some day, we will have
federated Gitea using ActivityPub.


## Articles of interest

* [Build Safety of Software in 28 Popular Home Routers](https://cyber-itl.org/assets/papers/2018/build_safety_of_software_in_28_popular_home_routers.pdf):
   "of the access points and routers we reviewed, not a single one
took full advantage of the basic application armoring features
provided by the operating system. Indeed, only one or two models even
came close, and no brand did well consistently across all models
tested"

* [A PPPoE Implementation for Linux](https://static.usenix.org/publications/library/proceedings/als00/2000papers/papers/full_papers/skoll/skoll_html/index.html): "Many DSL service providers use PPPoE for residential broadband Internet access. This paper briefly describes the PPPoE protocol, presents strategies for implementing it under Linux and describes in detail a user-space implementation of a PPPoE client."

* [PPP IPV6CP vs DHCPv6 at AAISP](https://www.revk.uk/2011/01/ppp-ipv6cp-vs-dhcpv6.html)
