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
  mkStringOption =
    description: mkOption { type = types.str; inherit description; };
in {
  options = {
    system.service.pppoe = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
    system.service.l2tp = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    system.service.pppoe = config.system.callService ./pppoe.nix {
      interface = mkOption {
        type = liminix.lib.types.service;
        description = "ethernet interface to run PPPoE over";
      };
      username = mkStringOption "username";
      password = mkStringOption "password";
      lcpEcho = {
        adaptive = mkOption {
          description = "send LCP echo-request frames only if no traffic was received from the peer since the last echo-request was sent";
          type = types.bool;
          default = true;
        };
        interval = mkOption {
          type = types.nullOr types.int;
          default = 3;
          description = "send an LCP echo-request frame to the peer every n seconds";
        };
        failure =  mkOption {
          type = types.nullOr types.int;
          default = 3;
          description = "terminate connection if n LCP echo-requests are sent without receiving a valid LCP echo-reply";
        };
      };
      debug = mkOption {
        description = "log the contents of all control packets sent or received";
        default = false;
        type = types.bool;
      };
      ppp-options = mkOption {
        type = types.listOf types.str;
        description = "options supplied on ppp command line";
        default = [];
      };
    };
    system.service.l2tp = config.system.callService ./l2tp.nix {
      lns = mkOption {
        type = types.str;
        description = "hostname or address of the L2TP network server";
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
        PPPOL2TP = "y";
        L2TP = "y";
      };
    };
  };
}
