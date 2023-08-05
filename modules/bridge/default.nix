{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.liminix.services) oneshot;
  inherit (pkgs) liminix;
in
{
  options = {
    system.service.bridge = {
      primary = mkOption {
        type = liminix.lib.types.serviceDefn;
      };
      members = mkOption {
        type = liminix.lib.types.serviceDefn;
      };
    };
  };
  config.system.service.bridge = {
    primary = liminix.callService ./primary.nix {
      ifname = mkOption {
        type = types.str;
        description = "interface name for the bridge device";
      };
    };
    members = liminix.callService ./members.nix {
      members = mkOption {
        type = types.listOf liminix.lib.types.service;
        description = "interfaces to add to the bridge";
      };
      primary = mkOption {
        type = liminix.lib.types.service;
        description = "bridge interface to add them to";
      };
    };
  };
  config.kernel.config.BRIDGE = "y";
}
