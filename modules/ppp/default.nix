## PPP
## ===
##
## A rudimentary PPPoE (PPP over Ethernet) configuration to address
## the case where your Liminix device is connected to an upstream
## network using PPPoE. This is typical for UK broadband connections
## (except "cable"), and common in some other localities as well: ask
## your ISP if this is you.

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
in {
  options = {
    system.service.pppoe = mkOption {
      type = types.functionTo types.package;
    };
  };
  config = {
    system.service.pppoe = pkgs.callPackage ./pppoe.nix {};
    kernel = {
      config = {
        PPP = "y";
        PPP_BSDCOMP = "y";
        PPP_DEFLATE = "y";
        PPP_ASYNC = "y";
        PPP_SYNC_TTY = "y";
      };
    };
  };
}
