Introduction
############

Liminix is a Nix-based collection of software tailored for domestic
wifi router or IoT device devices, of the kind that OpenWrt or DD-WRT
or Gargoyle or Tomato run on.

This is not NixOS-on-your-router: it's aimed at devices that are
underpowered for the full NixOS experience. It uses busybox tools,
musl instead of GNU libc, and s6-rc instead of systemd.

The Liminix name comes from Liminis, in Latin the genitive declension
of "limen", or "of the threshold". Your router stands at the threshold
of your (online) home and everything you send to/receive from the
outside word goes across it.
