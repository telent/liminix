## Dnsmasq
## =======
##
## This module includes a service to provide DNS, DHCP, and IPv6
## router advertisement for the local network.


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in {
  options = {
    system.service.dnsmasq = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    system.service.dnsmasq = liminix.callService ./service.nix {
      user = mkOption {
        type = types.str;
        default = "dnsmasq";
        description = "Specifies the unix user which dnsmasq will run as" ;
      };
      group = mkOption {
        type = types.str;
        default = "dnsmasq";
        description = "Specifies the unix group which dnsmasq will run as" ;
      };
      resolvconf = mkOption {
        type = types.nullOr liminix.lib.types.service;
        default = null;
      };
      interface = mkOption {
        type = liminix.lib.types.service;
        default = null;
      };
      upstreams = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      ranges = mkOption {
        type = types.listOf types.str;
      };
      hosts = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            mac = mkOption {
              description = ''
                MAC or other hardware address to match on. For Ethernet
                this is a 48 bit address represented as colon-separated
                hex bytes, or "id:clientid" to match a presented
                client id (IPv6 DUID)
              '';
              type = types.str;
              example = "01:20:31:4a:50";
            };
            v4 = mkOption  {
              description = "IPv4 address to assign to this client";
              example = "192.0.2.1";
              type = types.str;
            };
            v6 = mkOption  {
              type = types.listOf types.str;
              description = "IPv6 addresses or interface-ids to assign to this client";
              default = [];
              example = [ "fe80::42:1eff:fefd:b341" "::1234"];
            };
            leasetime = mkOption {
              type = types.int;
              default = 86400;
            };
          };
        });
      };
      domain = mkOption {
        # this can be given multiple times so probably should be
        # domains plural and list of string
        description = "Domain name for DHCP service: causes the DHCP server to return the domain to any hosts which request it, and sets the domain which it is legal for DHCP-configured hosts to claim";
        type = types.str;
        example = "example.com";
      };
    };
    users.dnsmasq = {
      uid = 51; gid= 51; gecos = "DNS/DHCP service user";
      dir = "/run/dnsmasq";
      shell = "/bin/false";
    };
    groups.dnsmasq = {
      gid = 51; usernames = ["dnsmasq"];
    };
    groups.system.usernames = ["dnsmasq"];
  };
}
