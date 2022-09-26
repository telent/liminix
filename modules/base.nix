{ lib, pkgs, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;

  type_service = types.package // {
    name = "service";
    description = "s6-rc service";
    check = x: isDerivation x && hasAttr "serviceType" x;
  };

in {
  options = {
    systemPackages = mkOption {
      type = types.listOf types.package;
    };
    services = mkOption {
      type = types.attrsOf type_service;
    };
    kernel = {
      config = mkOption {
        # mostly the values are y n or m, but sometimes
        # other strings are also used
        type = types.attrsOf types.nonEmptyStr;
      };
      checkedConfig = mkOption {
        type = types.attrsOf types.nonEmptyStr;
      };
    };
  };
}
