## IPv6 Autoconfiguration
## ======================
##
## Enable IPv6 neighbour discovery for an interface and allow it
## to participate in router solicitation/router advertisement.
##
## You need this if you want to get an IPv6 address (or addresses)
## whether by stateless allocation (SLAAC) or by DHCP6. You don't
## need this on interfaces that are members of bridges, because they
## shouldn't have addresses of their own.

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
  options.system.service.ipv6.autoconfig = mkOption {
    type = liminix.lib.types.serviceDefn;
  };

  config.system.service.ipv6 = {
    autoconfig = config.system.callService ./autoconfig.nix {
      interface = mkOption {
        type = liminix.lib.types.interface;
      };
      role = mkOption {
        description = "configure as host or router (controls whether accept_ra sis set)";
        type = types.enum [
          "host"
          "router"
        ];
        default = "host";
      };
      sysctl = mkOption {
        type = types.attrsOf types.str;
        description = "additional sysctl settings to apply to /proc/sys/net/ipv6/conf/<ifname>";
        default = { };
        example = {
          dad_transmits = 1;
          hop_limit = 64;
        };
      };
    };
  };
}
