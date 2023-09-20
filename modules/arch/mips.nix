{ lib, pkgs, config, ...}:
{
  config = {
    kernel.config = {
      MIPS_ELF_APPENDED_DTB = "y";
    };
    boot.commandLine = [
      "console=ttyS0,115200" # true of all mips we've yet encountered
    ];
  };
}
