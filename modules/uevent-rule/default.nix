# this is unlikely to be the final form or location of this code, it's
# an interim module which wraps the uevent-watch command

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
#  inherit (pkgs.liminix.services) bundle;
{
  options = {
    system.service.uevent-rule = mkOption {
      description = "a service which starts other services based on device state (sysfs)";
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    system.service.uevent-rule = config.system.callService ./rule.nix {
      serviceName = mkOption {
        description = "name of the service to run when the rule matches";
        type = types.str;
      };
      terms = mkOption {
        type = types.attrs;
        example = {
          devtype = "usb_device";
          attrs.idVendor = "8086";
        };
        default = { };
      };
      symlink = mkOption {
        description = "create symlink targeted on devpath";
        type = types.nullOr types.str;
        default = null;
      };
    };
  };
}
