## PPP
## ===
##
## ``ppoe`` (PPP over Ethernet) provides a service to address the case
## where your Liminix device is connected to an upstream network using
## PPPoE. This is typical for UK broadband connections where the
## physical connection is made by OpenReach ("Fibre To The X") and
## common in some other localities as well: check with your ISP if this is
## you.
##
## ``l2tp`` (Layer 2 Tunelling Protocol) provides a service that
## tunnels PPP over the Internet.  This may be used by some ISPs in
## conjunction with a DHCP uplink, or other more creative forms of
## network connection

{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in
{
  imports = [ ../secrets ];
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
      username = mkOption {
        type = types.nullOr (liminix.lib.types.replacable types.str);
        default = null;
        description = "username";
      };
      password = mkOption {
        type = types.nullOr (liminix.lib.types.replacable types.str);
        default = null;
        description = "password";
      };
      bandwidth = mkOption {
        type = types.nullOr (types.int);
        default = null;
        description = "approximate bandwidth in bytes/second. Used to calculate rate limits for ICMP";
      };
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
        failure = mkOption {
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
        default = [ ];
      };
    };
    system.service.l2tp = config.system.callService ./l2tp.nix {
      lns = mkOption {
        type = types.str;
        description = "hostname or address of the L2TP network server";
      };
      username = mkOption {
        type = types.nullOr (liminix.lib.types.replacable types.str);
        default = null;
        description = "username";
      };
      password = mkOption {
        type = types.nullOr (liminix.lib.types.replacable types.str);
        default = null;
        description = "password";
      };
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
        failure = mkOption {
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
        default = [ ];
        description = "options supplied on ppp command line";
      };
    };

    # rp-pppoe attempts to drop privs by switching to user "nobody"
    users.nobody = {
      uid = 65534;
      gid = 65534;
      gecos = "Captain Nemo";
      dir = "/run/";
      shell = "/bin/false";
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
