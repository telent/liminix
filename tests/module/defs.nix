{ lib, ...}:
let inherit (lib) mkEnableOption mkOption types;
in {
  options = {
    services.a = {
      enable = mkEnableOption "hello service";
    };
    services.b = {
      enable = mkEnableOption "other service";
    };
    services.z = mkOption {   };
    systemPackages = mkOption {
      type = types.listOf types.package;
    };
  };
}
