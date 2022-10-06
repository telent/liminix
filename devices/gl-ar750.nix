# GL.INet GL-AR750 "Creta" travel router
#  - QCA9531 @650Mhz SoC
#  - dual band wireless: IEEE 802.11a/b/g/n/ac
#  - two 10/100Mbps LAN ports and one WAN
#  - 128MB DDR2 RAM / 16MB  NOR Flash
#  - "ath79" soc family
# https://www.gl-inet.com/products/gl-ar750/

# I like GL.iNet devices because they're relatively accessible to
# DIY users: the serial port connections have headers preinstalled
# and don't need soldering

{
  system = {
    crossSystem = {
      config = "mips-unknown-linux-musl";
      gcc = {
        abi = "32";
        arch = "mips32";          # maybe mips_24kc-
      };
    };
  };
  kernel = rec {
    checkedConfig = {
      "MIPS_ELF_APPENDED_DTB" = "y";
      # possibly not all of these are needed, I just
      # copied them from qemu
      HW_CONSOLE = "y";
      VT_HW_CONSOLE_BINDING = "y";
      SERIAL_8250_CONSOLE = "y";
      SERIAL_8250 = "y";
      SERIAL_CORE_CONSOLE = "y";
      DUMMY_CONSOLE = "y";
      DUMMY_CONSOLE_COLUMNS = "80";
      DUMMY_CONSOLE_ROWS = "25";
      # FRAMEBUFFER_CONSOLE = "y";
      CONSOLE_LOGLEVEL_DEFAULT = "8";
      CONSOLE_LOGLEVEL_QUIET = "4";


      # "empty" initramfs source should create an initial
      # filesystem that has a /dev/console node and not much
      # else.  Note that pid 1 is started *before* the root
      # filesystem is mounted and it expects /dev/console to
      # be present already
      BLK_DEV_INITRD = "n";
    };
    config = checkedConfig // {
      CPU_LITTLE_ENDIAN= "n";
      CPU_BIG_ENDIAN= "y";
      ATH79 = "y";
      MIPS_ELF_APPENDED_DTB = "y";

#      INITRAMFS_SOURCE = "\"\"";

      # this is all copied from nixwrt ath79 config. Clearly not all
      # of it is device config, some of it is wifi config or
      # installation method config or ...

      "CMDLINE_PARTITION" = "y";
      "DEBUG_INFO" = "y";
      "EARLY_PRINTK" = "y";
      "FW_LOADER" = "y";
      # we don't have a user helper, so we get multiple 60s pauses
      # at boot time unless we disable trying to call it
      "FW_LOADER_USER_HELPER" = "n";

      # "IMAGE_CMDLINE_HACK" = "n";

      "MODULE_SIG" = "y";
      "MTD_CMDLINE_PARTS" = "y";
#      "MTD_SPLIT_FIRMWARE" = "y";
      "PARTITION_ADVANCED" = "y";
      "PRINTK_TIME" = "y";
      "SQUASHFS" = "y";
      "SQUASHFS_XZ" = "y";
      # "ASN1" = "y";
      # "ASYMMETRIC_KEY_TYPE" = "y";
      # "ASYMMETRIC_PUBLIC_KEY_SUBTYPE" = "y";
      # "CRC_CCITT" = "y";
      # "CRYPTO" = "y";
      # "CRYPTO_ARC4" = "y";
      # "CRYPTO_CBC" = "y";
      # "CRYPTO_CCM" = "y";
      # "CRYPTO_CMAC" = "y";
      # "CRYPTO_GCM" = "y";
      # "CRYPTO_HASH_INFO" = "y";
      # "CRYPTO_LIB_ARC4" = "y";
      # "CRYPTO_RSA" = "y";
      # "CRYPTO_SHA1" = "y";
      # "ENCRYPTED_KEYS" = "y";
      # "KEYS" = "y";
    };
  };
  outputs.default = "directory";
  boot = {
    loadAddress = "0x80060000";
    entryPoint  = "0x80060000";
  };
}
