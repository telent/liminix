{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
in {
  options = {
    system.service.dnsmasq = mkOption {
      type = types.functionTo types.package;
    };
  };
  config = {
    system.service.dnsmasq = pkgs.callPackage ./service.nix {};
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
