## VLAN
## ====
##
## Virtual LANs give you the ability to sub-divide a LAN. Linux can
## accept VLAN tagged traffic and presents each VLAN ID as a
## different network interface (eg: eth0.100 for VLAN ID 100)
##
## Some Liminix devices with multiple ethernet ports are implemented
## using a network switch connecting the physical ports to the CPU,
## and require using VLAN in order to send different traffic to
## different ports (e.g. LAN vs WAN)

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.liminix.services) oneshot;
  inherit (pkgs) liminix;
in
{
  options = {
    system.service.vlan = mkOption { type = liminix.lib.types.serviceDefn; };
  };
  config.system.service.vlan = liminix.callService ./service.nix {
    ifname = mkOption {
      type = types.str;
      description = "interface name to create";
    };
    primary = mkOption {
      description = "existing physical interface";
      type = liminix.lib.types.interface;
    };
    vid = mkOption {
      description = "VLAN identifier (VID) in range 1-4094";
      type = types.str;
    };
  };
  config.kernel.config = {
    VLAN_8021Q = "y";
    SWCONFIG = "y"; # not always appropriate, some devices will use DSA
  };
}
