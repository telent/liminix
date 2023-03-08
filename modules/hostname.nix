{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.liminix.services) oneshot;
in {
  options = {
    hostname = mkOption {
      default = "liminix";
      type = types.nonEmptyStr;
    };
  };
  config = {
    services.hostname = oneshot {
      name = "hostname";
      up = "echo ${config.hostname} > /proc/sys/kernel/hostname";
      down = "true";
    };
  };
}
