## NTP
## ===
##
## A network time protocol implementation so that your Liminix device
## may synchronize its clock with an accurate time source, and
## optionally also provide time service to its peers. The
## implementation used in Liminix is Chrony

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
  serverOpts = types.listOf types.str;
in {
  options = {
    system.service.ntp = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    system.service.ntp = config.system.callService ./service.nix {
      user = mkOption {
        type = types.str;
        default = "ntp";
      };
      servers = mkOption { type = types.attrsOf serverOpts; default = {}; };
      pools = mkOption { type = types.attrsOf serverOpts; default = {}; };
      peers = mkOption { type = types.attrsOf serverOpts; default = {}; };
      makestep = mkOption {
        default = null;
        type = types.nullOr
          (types.submodule {
            options = {
              threshold = mkOption { type = types.number; default = null;};
              limit = mkOption { type = types.number; };
            };
          });
      };
      allow = mkOption {
        description = "subnets from which NTP clients are allowed to access the server";
        type = types.listOf types.str;
        default = [];
      };
      bindaddress = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      binddevice = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      dumpdir = mkOption {
        internal = true;
        type = types.path;
        default = "/run/chrony";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };
    users.ntp = {
      uid = 52; gid= 52; gecos = "Unprivileged NTP user";
      dir = "/run/ntp";
      shell = "/bin/false";
    };
    # groups.system.usernames = ["ntp"];
  };
}
