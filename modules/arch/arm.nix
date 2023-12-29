{ lib, lim, pkgs, config, ...}:
{
  config = {
    kernel.config = {
      OF = "y";
    };
    hardware.ram.startAddress = lim.parseInt "0x40000000";
    system.outputs.u-boot = pkgs.ubootQemuArm;
  };
}
