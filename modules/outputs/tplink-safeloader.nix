{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types;
  o = config.system.outputs;
  cfg = config.tplink-safeloader;
in {
  options.tplink-safeloader = {
    board = mkOption {
      type = types.str;
    };
  };
  options.system.outputs = {
    tplink-safeloader = mkOption {
      type = types.package;
      description = ''
        tplink-safeloader
        *****************

        For creating 'safeloader' images for tp-link devices.

        These can be flashed to the device using the firmware update feature
        in the TP-link web UI or the OEM bootloader recovery: Use something
        sharp to hold the 'reset' button while turning on the router until
        only the orange LED remains lit. The router will assume IP address
        192.168.0.1 and expect you to take 192.168.0.5 on one of the LAN ports.
        On NixOS, use something like::

            networking.interfaces.enp0s20f0u1c2 = {
              ipv4.addresses = [ {
                address = "192.168.0.5";
                prefixLength = 24;
              } ];
            };
            networking.networkmanager = {
                unmanaged = [ "enp0s20f0u1c2" ];
            };

        This connection is rather somewhat temperamental, it may take a couple
        of attempts, possibly re-attaching the USB dongle and running
        ``systemctl restart network-start.service``. The web interface does not
        give accurate feedback (the progress bar is a lie), so you may want
        to upload the firmware using ``curl -F firmware=@result http://192.168.0.1/f2.htm``.
        After this shows a 'success' JSON, the image still needs to be
        transferred from memory to flash, so be patient.
      '';
    };
  };
  config = {
    system.outputs = rec {
      tplink-safeloader =
        pkgs.runCommand "tplink" { nativeBuildInputs = with pkgs.pkgsBuildBuild; [ firmware-utils ];  } ''
        tplink-safeloader -B "${cfg.board}" -k "${o.uimage}" -r "${o.rootfs}" -o $out
        '';
    };
  };
}
