{ config, pkgs, lib, ... } :
let
  inherit (pkgs) liminix;
  inherit (lib) mkOption types;
in {
  options.system.service.ifwait =
    mkOption { type = liminix.lib.types.serviceDefn; };

  config.system.service.ifwait = config.system.callService ./ifwait.nix {
    state = mkOption { type = types.str; };
    interface = mkOption {
      type = liminix.lib.types.interface;
    };
    service = mkOption {
      type = liminix.lib.types.service;
    };
  };
}
