{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  inherit (pkgs) liminix writeText;
  o = config.system.outputs;
in
{
  options.system.outputs.uimage = mkOption {
    type = types.package;
    internal = true;
    description = ''
      uimage
      ******

      Combined kernel and FDT in uImage (U-Boot compatible) format
    '';
  };
  config.system.outputs.uimage = liminix.builders.uimage {
    commandLine = concatStringsSep " " config.boot.commandLine;
    inherit (config.boot) commandLineDtbNode;
    inherit (config.hardware) loadAddress entryPoint alignment;
    inherit (config.boot) imageFormat;
    inherit (o) kernel dtb;
  };
}
