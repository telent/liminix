{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.liminix.services) oneshot;
in
{
  options = {
    system.service.bridge = {
      primary = mkOption {
        type = types.functionTo pkgs.liminix.lib.types.service;
      };
      members = mkOption {
        type = types.functionTo pkgs.liminix.lib.types.service;
      };
    };
  };
  config = {
    system.service.bridge.primary = pkgs.callPackage ./primary.nix {};
    system.service.bridge.members = pkgs.callPackage ./members.nix {};
    kernel.config.BRIDGE = "y";
  };
}
