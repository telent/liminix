{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption; # types concatStringsSep;
in
{
  options = {
    boot = {
      ramdisk = {
        enable = mkEnableOption ''
          reserving part of memory as
          an MTD-based RAM disk.  Needed for TFTP booting
        '';
      };
    };
  };
  config = mkIf config.boot.ramdisk.enable {
    kernel = {
      config = {
        MTD = "y";
        MTD_PHRAM = "y";
        MTD_CMDLINE_PARTS = "y";
        MTD_OF_PARTS = "y";
        PARTITION_ADVANCED = "y";
        MTD_BLKDEVS = "y";
        MTD_BLOCK = "y";
      };
    };
  };
}
