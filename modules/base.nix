{ lib, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
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
    kernel = mkOption {
      type = types.anything;
    };
  };
}
