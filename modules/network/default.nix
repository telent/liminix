## Network
## =======
##
## Basic network services for creating hardware ethernet devices
## and adding addresses


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
  inherit (pkgs.liminix.services) bundle;
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
      route = mkOption {
        type = liminix.lib.types.serviceDefn;
      };
      dhcp = {
        client = mkOption {
          # this needs to move to its own service as it has
          # busybox config
          description = "DHCP v4 client";
          type = liminix.lib.types.serviceDefn;
        };
      };
    };
  };
  config = {
    hardware.networkInterfaces = {
      lo =
        let
          net = config.system.service.network;
          iface = net.link.build { ifname = "lo";};
        in bundle {
          name = "loopback";
          contents = [
            ( net.address.build {
              interface = iface;
              family = "inet";
              address ="127.0.0.1";
              prefixLength = 8;
            })
            ( net.address.build {
              interface = iface;
              family = "inet6";
              address = "::1";
              prefixLength = 128;
            })
          ];
        };
    };
    services.loopback = config.hardware.networkInterfaces.lo;

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

      route = liminix.callService ./route.nix {
        interface = mkOption {
          type = types.nullOr liminix.lib.types.interface;
          default = null;
          description = "Interface to route through. May be omitted if it can be inferred from \"via\"";
        };
        target = mkOption {
          type = types.str;
          description = "host or network to add route to";
        };
        via = mkOption {
          type = types.str;
          description = "address of next hop";
        };
        metric = mkOption {
          type = types.int;
          description = "route metric";
          default = 100;
        };
      };

      dhcp.client = liminix.callService ./dhcpc.nix {
        interface = mkOption {
          type = liminix.lib.types.service;
        };
      };

    };
  };
}
