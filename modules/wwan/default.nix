{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) liminix;
  inherit (lib) mkOption types;
  huawei-cdc-ncm = pkgs.kmodloader.override {
    targets = [ "huawei_cdc_ncm" ];
    inherit (config.system.outputs) kernel;
  };
in
{
  imports = [
    ../uevent-rule
    ../mdevd.nix
  ];

  options = {
    system.service.wwan.huawei-e3372 = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    kernel.config = {
      USB_NET_HUAWEI_CDC_NCM = "m";
      USB_USBNET = "y";
      USB_SERIAL = "y";
      USB_SERIAL_OPTION = "y";
    };
    programs.busybox.applets = [
      "insmod"
      "rmmod"
    ];

    # https://www.0xf8.org/2017/01/flashing-a-huawei-e3372h-4g-lte-stick-from-hilink-to-stick-mode/
    system.service.wwan.huawei-e3372 =
      let
        svc = config.system.callService ./huawei-e3372.nix {
          apn = mkOption { type = types.str; };
          username = mkOption { type = types.str; };
          password = mkOption { type = types.str; };
          authType = mkOption {
            type = types.enum [
              "pap"
              "chap"
            ];
          };
        };
      in
      svc
      // {
        build =
          args:
          let
            args' = args // {
              dependencies = (args.dependencies or [ ]) ++ [ huawei-cdc-ncm ];
            };
          in
          svc.build args';
      };
  };
}
