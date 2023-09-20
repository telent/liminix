{ lib, pkgs, config, ...}:
{
  imports = [ ./mips.nix ];
  config = {
    kernel.config = {
      CPU_LITTLE_ENDIAN = "y";
    };
  };
}
