## Watchdog
##
## Enable hardware watchdog (for devices that support one) and
## feed it by checking the health of specified critical services.
## If the watchdog feeder stops, the device will reboot.

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in
{
  options = {
    system.service.watchdog =  mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config.system.service.watchdog = config.system.callService ./watchdog.nix {
    watched = mkOption {
      description = "services to watch";
      type = types.listOf liminix.lib.types.service;
    };
    headStart = mkOption {
      description = "delay in seconds before watchdog starts checking service health";
      default = 60;
      type = types.int;
    };
  };
  config.kernel.config.WATCHDOG = "y";
}
