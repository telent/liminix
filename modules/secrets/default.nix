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
  };
}
