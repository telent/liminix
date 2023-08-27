## Network
## =======
##
## Basic network services for creating hardware ethernet devices
## and adding addresses


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in {
  options = {
    system.service.network = {
      link = mkOption {
        description = "hardware network interface";
        type = liminix.lib.types.serviceDefn;
      };
      address = mkOption {
        description = "network interface address";
        type = liminix.lib.types.serviceDefn;
      };
    };
  };
  config = {
    system.service.network = {
      link = liminix.callService ./link.nix {
        ifname = mkOption {
          type = types.str;
          example = "eth0";
        };
        # other "ip link add" options could go here as well
        mtu = mkOption {
          type = types.nullOr types.int;
          example = 1480;
        };
      };
      address = liminix.callService ./address.nix {
        interface = mkOption {
          type = liminix.lib.types.service;
        };
        family = mkOption {
          type = types.enum [ "inet" "inet6" ];
        };
        address = mkOption {
          type = types.str;
        };
        prefixLength = mkOption {
          type = types.ints.between 0 128;
        };
      };
    };
  };
}
