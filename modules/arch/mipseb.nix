{ pkgs, config, ... }:
{
  imports = [ ./mips.nix ];
  config = {
    kernel.config = {
      CPU_BIG_ENDIAN = "y";
    };
    system.outputs.u-boot = pkgs.ubootQemuMips;
  };
}
