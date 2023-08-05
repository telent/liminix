{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in {
  options = {
    system.service.hostapd = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    system.service.hostapd = liminix.callService ./service.nix {
      interface = mkOption {
        type = liminix.lib.types.service;
      };
      params = mkOption {
        type = types.attrs;
      };
    };
  };
}
