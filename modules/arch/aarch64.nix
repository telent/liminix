{ lib, lim, pkgs, config, ...}:
{
  config = {
    kernel.config = {
      CPU_LITTLE_ENDIAN= "y";
      CPU_BIG_ENDIAN= "n";
      # CMDLINE_FROM_BOOTLOADER availability is conditional
      # on CMDLINE being set to something non-empty
      CMDLINE="\"empty=false\"";
      CMDLINE_FROM_BOOTLOADER = "y";

      OF = "y";
      # USE_OF = "y";
    };
    hardware.ram.startAddress = lim.parseInt "0x40000000";
    system.outputs.u-boot = pkgs.ubootQemuAarch64;
  };
}
