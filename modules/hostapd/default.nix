{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
in {
  options = {
    system.service.hostapd = mkOption {
      type = types.functionTo types.package;
    };
  };
  config = {
    system.service.hostapd = pkgs.callPackage ./service.nix {};
  };
}
