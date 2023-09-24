## DHCP6 client module
## ===================
##
##  This is for use if you have an IPv6-capable upstream that provides
##  address information and/or prefix delegation using DHCP6. It
##  provides a service to request address information in the form of a
##  DHCP lease, and two dependent services that listen for updates
##  to the DHCP address information and can be used to update
##  addresses of network interfaces that you want to assign those
##  prefixes to

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.liminix.services) oneshot;
  inherit (pkgs) liminix;
in
{
  options = {
    system.service.dhcp6c = {
      client = mkOption { type = liminix.lib.types.serviceDefn; };
      prefix = mkOption { type = liminix.lib.types.serviceDefn; };
      address = mkOption { type = liminix.lib.types.serviceDefn; };
    };
  };
  config.system.service.dhcp6c = {
    client = liminix.callService ./client.nix {
      interface = mkOption {
        type = liminix.lib.types.interface;
        description = "interface (usually WAN) to query for DHCP6";
      };
    };
    address = liminix.callService ./address.nix {
      client = mkOption {
        type = types.anything; # liminix.lib.types.service;
      };
      interface = mkOption {
        type = liminix.lib.types.interface;
        description = "interface to assign the address to";
      };
    };
    prefix = liminix.callService ./prefix.nix {
      client = mkOption {
        type = types.anything; # liminix.lib.types.service;
      };
      interface = mkOption {
        type = liminix.lib.types.interface;
        description = "interface to assign <prefix>::1 to";
      };
    };
  };
}
