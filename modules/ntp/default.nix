{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
in {
  options = {
    system.service.ntp = mkOption {
      type = types.functionTo types.package;
    };
  };
  config = {
    system.service.ntp = pkgs.callPackage ./service.nix {};
    users.ntp = {
      uid = 52; gid= 52; gecos = "Unprivileged NTP user";
      dir = "/run/ntp";
      shell = "/bin/false";
    };
    # groups.system.usernames = ["ntp"];
  };
}
