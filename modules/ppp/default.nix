## PPP
## ===
##
## A PPPoE (PPP over Ethernet) configuration to address the case where
## your Liminix device is connected to an upstream network using
## PPPoE. This is typical for UK broadband connections where the
## physical connection is made by OpenReach ("Fibre To The X") and
## common in some other localities as well: ask your ISP if this is
## you.

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in {
  options = {
    system.service.pppoe = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    system.service.pppoe = pkgs.liminix.callService ./pppoe.nix {
      interface = mkOption {
        type = liminix.lib.types.service;
        description = "ethernet interface to run PPPoE over";
      };
      ppp-options = mkOption {
        type = types.listOf types.str;
        description = "options supplied on ppp command line";
      };
    };
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
