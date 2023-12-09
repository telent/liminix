## Hardware-dependent options
## ==========================
##
## These are attributes of the hardware not of the application
## you want to run on it, and would usually be set in the "device" file:
## :file:`devices/manuf-model/default.nix`


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
in {
  options = {
    boot = {
    };
    hardware = {
      dts = {
        src = mkOption {
          type = types.nullOr types.path;
          description = ''
            If the device requires an external device tree to be loaded
            alongside the kernel, this is the path to the device tree source
            (we usually get these from OpenWrt). This value may be null if the
            platform creates the device tree - currently this is the case
            only for QEMU.
          '';
        };
        includes = mkOption {
          default = [];
          description = "List of directories to search for DTS includes (.dtsi files)";
          type = types.listOf types.path;
        };
      };
      defaultOutput = mkOption {
        description = "\"Default\" output: what gets built for this device when outputs.default is requested. Typically this is \"flashimage\" or \"vmroot\"";
        type = types.nonEmptyStr;
      };
      ram = {
        startAddress = mkOption {
          type = types.int;
        };
      };

      flash = {
        # start address and size of whichever partition (often
        # called "firmware") we're going to overwrite with our
        # kernel uimage and root fs. Not the entire flash, as
        # that often also contains the bootloader, data for
        # for wireless devices, etc
        address = mkOption {
          description = ''
            Start address of whichever partition (often
            called "firmware") we're going to overwrite with our
            kernel uimage and root fs. Usually not the entire flash, as
            we don't want to clobber the bootloader, calibration data etc
          '';
          type = types.ints.unsigned;
        };
        size = mkOption {
          type = types.ints.unsigned;
          description = "Size in bytes of the firmware partition";
        };
        eraseBlockSize = mkOption {
          description = "Flash erase block size in bytes";
          type = types.ints.unsigned;
        };
      };
      loadAddress = mkOption { type = types.ints.unsigned; default = null; };
      entryPoint = mkOption { type = types.ints.unsigned; };
      radios = mkOption {
        description = ''
          Kernel modules (from mac80211 package) required for the
          wireless devices on this board
        '';
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
