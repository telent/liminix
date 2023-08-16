## Bridge module
## =============
##
##  Allows creation of Layer 2 software "bridge" network devices.  A
##  common use case is to merge together a hardware Ethernet device
##  with one or more WLANs so that several local devices appear to be
##  on the same network. Create a ``primary`` service to specify the
##  new device, and a ``members`` service to add constituent devices
##  to it.


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.liminix.services) oneshot;
  inherit (pkgs) liminix;
in
{
  options = {
    system.service.bridge = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config.system.service = {
    bridge = liminix.callService ./service.nix {
      members = mkOption {
        type = types.listOf liminix.lib.types.service;
        description = "interfaces to add to the bridge";
      };
      ifname = mkOption {
        type = types.str;
        description = "bridge interface name to create";
      };
    };
  };
  config.kernel.config.BRIDGE = "y";
}
