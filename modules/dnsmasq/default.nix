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
      };
      group = mkOption {
        type = types.str;
        default = "dnsmasq";
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
