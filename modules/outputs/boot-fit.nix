{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  inherit (pkgs.pseudofile) dir symlink;
  cfg = config.boot.loader.fit;
  o = config.system.outputs;
in
{
  options.boot.loader.fit.enable = mkEnableOption "FIT in /boot";

  config = mkIf cfg.enable {
    system.outputs.bootfiles = pkgs.runCommand "boot-fit" { } ''
      mkdir $out
      cd $out
      cp ${o.uimage} fit
    '';
    filesystem = dir {
      boot = symlink config.system.outputs.bootfiles;
    };
  };
}
