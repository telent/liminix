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

## What about NixWRT?

This is an in-progress rewrite of NixWRT, incorporating Lessons
Learned.

## Documentation

Documentation is in the [doc](doc/) directory. You can build it
by running

    nix-shell -p sphinx --run "make -C doc html"
