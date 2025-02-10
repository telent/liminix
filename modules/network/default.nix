## Network
## =======
##
## Basic network services for creating hardware ethernet devices
## and adding addresses

{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
  inherit (pkgs.liminix.services) bundle;
in
{
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
      forward = mkOption {
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
          iface = net.link.build { ifname = "lo"; };
        in
        bundle {
          name = "loopback";
          contents = [
            (net.address.build {
              interface = iface;
              family = "inet";
              address = "127.0.0.1";
              prefixLength = 8;
            })
            (net.address.build {
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
      link = config.system.callService ./link.nix {
        ifname = mkOption {
          type = types.str;
          example = "eth0";
          description = ''
            Device name as used by the kernel (as seen in "ip link"
            or "ifconfig" output). If devpath is also specified, the
            device will be renamed to the name provided.
          '';
        };
        devpath = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/devices/platform/soc/soc:internal-regs/f1070000.ethernet";
          description = ''
            Path to the sysfs node of the device. If you provide this
            and the ifname option, the device will be renamed to the
            name given by ifname.
          '';
        };
        # other "ip link add" options could go here as well
        mtu = mkOption {
          type = types.nullOr types.int;
          example = 1480;
        };
      };
      address = config.system.callService ./address.nix {
        interface = mkOption {
          type = liminix.lib.types.service;
        };
        family = mkOption {
          type = types.enum [
            "inet"
            "inet6"
          ];
        };
        address = mkOption {
          type = types.str;
        };
        prefixLength = mkOption {
          type = types.ints.between 0 128;
        };
      };

      route = config.system.callService ./route.nix {
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

      forward = config.system.callService ./forward.nix {
        enableIPv4 = mkOption {
          type = types.bool;
          default = true;
        };
        enableIPv6 = mkOption {
          type = types.bool;
          default = true;
        };
      };

      dhcp.client = config.system.callService ./dhcpc.nix {
        interface = mkOption {
          type = liminix.lib.types.service;
        };
      };

    };
  };
}
