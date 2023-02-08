# ppp-server

To test a router, we need an upstream connection. This directory
contains a derivation to download, start and configure a RouterOS
"Cloud Hosted Router" instance in a Qemu VM. It is currently
set up for automated tests only, and may require some manual
frobbing to run interactively.

Note that you need to open some multicast ports if you're using the
NixOS firewall (or probably, any other firewall). For iptables you can
accomplish this by editing your configuration.nix or some module it
calls:


```
    networking.firewall.extraCommands = ''
      ip46tables -A nixos-fw -m pkttype --pkt-type multicast -p udp --dport 1234:1236 -j nixos-fw-accept
    '';
```

## Provenance

The chr-7.x.img image is taken from https://mikrotik.com/download -
look in the section titled "Cloud Hosted Router" for "Raw disk image".
Note that this is proprietary software: please read the license
information and make sure you're using it legally.
