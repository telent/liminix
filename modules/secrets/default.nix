## Secrets

## various ways to manage secrets without writing them to the
## nix store

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
  inherit (pkgs.liminix.services) longrun;
in {
  options.system.service.secrets = {
    outboard = mkOption {
      description = "fetch secrets from external vault with https";
      type = liminix.lib.types.serviceDefn;
    };
    subscriber = mkOption {
      description = "wrapper around a service that needs notifying (e.g. restarting) when secrets change";
      type = liminix.lib.types.serviceDefn;
    };

  };
  config.system.service.secrets = {
    outboard = config.system.callService ./outboard.nix {
      url = mkOption {
        description = "source url";
        type = types.strMatching "https?://.*";
      };
      name = mkOption {
        description = "service name";
        type = types.str;
      };
      interval =  mkOption {
        type = types.int;
        default = 30;
        description = "how often to check the source, in minutes";
      };
    };
    subscriber = config.system.callService ./subscriber.nix {
      watch = {
        service = mkOption {
          description = "secrets service to subscribe to";
          type = liminix.lib.types.service;
        };
        paths = mkOption {
          description = "list of output paths we are interested in";
          example = ["wan/l2tp" "wifi/wlan5"];
          type = types.listOf types.str;
        };
      };
      service = mkOption {
        description = "subscribing service that will receive notification";
        type = liminix.lib.types.service;
      };
      action = mkOption {
        description = "how do we notify the service to regenerate its config";
        default = "restart-all";
        type = types.enum [
          "restart" "restart-all"
          "hup" "int" "quit" "kill" "term"
          "winch" "usr1" "usr2"
        ];
      };
    };
  };
}
