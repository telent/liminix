{ device } :
{ lib, ...}:
let inherit (lib) mkEnableOption mkOption types;
in {
  options = {
    systemPackages = mkOption {
      type = types.listOf types.package;
    };
    services = mkOption {
      type = types.anything;
    };
    kernel = mkOption {
      type = types.anything;
      default = { inherit (device.kernel) config checkedConfig; };
    };
  };
}
