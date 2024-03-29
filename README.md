# Liminix

A Nix-based system for configuring consumer wifi routers or IoT device
devices, of the kind that OpenWrt or DD-WRT or Gargoyle or Tomato run
on. It's a reboot/restart/rewrite of NixWRT.

This is not NixOS-on-your-router: it's aimed at devices that are
underpowered for the full NixOS experience. It uses busybox tools,
musl instead of GNU libc, and s6-rc instead of systemd.

The Liminix name comes from Liminis, in Latin the genitive declension
of "limen", or "of the threshold". Your router stands at the threshold
of your (online) home and everything you send to/receive from the
outside word goes across it.


## Current status (does it work yet?)

Liminix is pre-1.0. We are still finding new and better ways to do things,
and there is no attempt to maintain backward compatibility with the old
ways.

The [NEWS](NEWS) file (available wherever you found this README) is
a high-level overview of breaking changes.

Development mostly happens on the `main` branch, which is therefore
not guaranteed to build or to work on every commit. For the latest
functioning version, see [the CI system](https://build.liminix.org/jobset/liminix/build) and pick a revision with all jobs green.


## Documentation

Documentation is in the [doc](doc/) directory. You can build it
by running

    nix-shell -p sphinx --run "make -C doc hardware.rst html"

Rendered documentation corresponding to the latest commit on `main`
is published to [https://www.liminix.org/doc/](https://www.liminix.org/doc/)


## Extremely online

There is a #liminix IRC channel on the [OFTC](https://www.oftc.net/)
network in which you are welcome. You can also connect with a Matrix
client by joining the room `#_oftc_#liminix:matrix.org`.

In the IRC channel, as in all Liminix project venues, please conduct yourself
according to the Liminix [Code of Conduct](CODE-OF-CONDUCT.md).
