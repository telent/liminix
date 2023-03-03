{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
in {
  options = {
    boot = {
    };
    device = {
      dts = {
        src = mkOption { type = types.path; };
        includes = mkOption {
          default = [];
          type = types.listOf types.path;
        };
      };
      defaultOutput = mkOption {
        type = types.nonEmptyStr;
      };
      flash = {
        address = mkOption { type = types.str; };
        size = mkOption { type = types.str; };
      };
      loadAddress = mkOption { default = null; };
      entryPoint = mkOption { };
      radios = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["ath9k" "ath10k"];
      };
      rootDevice = mkOption { };
      networkInterfaces = mkOption {
        type = types.attrsOf types.anything;
      };
    };
  };
}
