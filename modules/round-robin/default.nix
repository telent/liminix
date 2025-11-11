## Round Robin
##
## Given a list of services, run each in turn until it exits, then
## runs the next.

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
{
  options = {
    system.service.round-robin = mkOption {
      description = "run services one at a time and failover to next";
      type = liminix.lib.types.serviceDefn;
    };
  };
  config.system.service.round-robin = config.system.callService ./service.nix {
    services = mkOption {
      type = types.listOf liminix.lib.types.service;
    };
    name = mkOption {
      type = types.str;
    };
  };
}
