{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  inherit (pkgs) runCommand;
in
{
  options = {
    system.outputs = {
      systemConfiguration = mkOption {
        type = types.package;
        description = ''
          pkgs.systemconfig for the configured filesystem,
          contains 'activate' and 'init' commands
        '';
        internal = true;
      };
    };
  };
  config = {
    system.outputs.systemConfiguration = pkgs.systemconfig config.filesystem.contents;
  };
}
