{ lib, pkgs, config, ...}:
{
  imports = [ ./mips.nix ];
  config = {
    kernel.config = {
      CPU_BIG_ENDIAN = "y";
    };
  };
}
