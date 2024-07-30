## Health check
##
## Runs a service and a separate periodic health process. When the
## health check starts failing over a period of time, kill the service.
## (Usually that means the supervisor will restart it, but you can
## have other behaviours by e.g. combining this service with a round-robin
## for failover)


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
#  inherit (pkgs.liminix.services) longrun;
in {
  options = {
    system.service.health-check = mkOption {
      description = "run a service while periodically checking it is healthy";
      type = liminix.lib.types.serviceDefn;
    };
  };
  config.system.service.health-check = config.system.callService ./service.nix {
    service = mkOption {
      type = liminix.lib.types.service;
    };
    interval =  mkOption {
      description = "interval between checks, in seconds";
      type = types.int;
      default = 10;
      example = 10;
    };
    threshold =  mkOption {
      description = "number of consecutive failures required for the service to be kicked";
      type = types.int;
      example = 3;
    };
    healthCheck = mkOption {
      description = "health check command or script. Expected to exit 0 if the service is healthy or any other exit status otherwise";
      type = types.path;
    };
  };
  config.programs.busybox.applets = ["expr"];
}
