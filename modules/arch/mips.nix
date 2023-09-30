{ lib, pkgs, config, ...}:
{
  config = {
    kernel.config = {
      MIPS_ELF_APPENDED_DTB = "y";
      MIPS_BOOTLOADER_CMDLINE_REQUIRE_COOKIE = "y";
      MIPS_BOOTLOADER_CMDLINE_COOKIE = "\"liminix\"";
      MIPS_CMDLINE_DTB_EXTEND = "y";

      OF = "y";
      USE_OF = "y";
    };
    boot.commandLine = [
      "console=ttyS0,115200" # true of all mips we've yet encountered
    ];
  };
}
