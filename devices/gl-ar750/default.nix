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

# Mainline linux 5.19 doesn't have device-tree support for this device
# or even for the SoC, so we use the extensive OpenWrt kernel patches

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

  # We need to be able to import default.nix before we import nixpkgs
  # because it has the system config to tell nixpkgs what arch to build for.
  # But we also need some way to do things like fetchFromGitHub in the
  # per-device config and we can only do that once we have a reference to
  # pkgs

  overlay = final: prev:
    let
      inherit (final) fetchFromGitHub fetchgit stdenvNoCC;
      openwrt = fetchFromGitHub {
        name = "openwrt-source";
        repo = "openwrt";
        owner = "openwrt";
        rev = "a5265497a4f6da158e95d6a450cb2cb6dc085cab";
        hash = "sha256-YYi4gkpLjbOK7bM2MGQjAyEBuXJ9JNXoz/JEmYf8xE8=";
      };
      mainline = fetchFromGitHub {
        name = "kernel-source";
        owner = "torvalds";
        repo = "linux";
        rev = "90c7e9b400c751dbd73885f494f421f90ca69721";
        hash = "sha256-pq6QNa0PJVeheaZkuvAPD0rLuEeKrViKk65dz+y4kqo=";
      };
    in {
      sources = {
        inherit openwrt;
        kernel = stdenvNoCC.mkDerivation {
          name = "spindled-kernel-tree";
          src = mainline;
          phases = [
            "unpackPhase" "patchPhase" "openWrtPatchPhase"
            "patchScripts" "installPhase"
          ];
          patches = [ ../../kernel/random.patch ];
          patchScripts = ''
            patchShebangs scripts/
          '';
          openWrtPatchPhase = ''
            cp -av ${openwrt}/target/linux/generic/files/* .
            chmod -R u+w .
            cp -av ${openwrt}/target/linux/ath79/files/* .
            chmod -R u+w .
            patches() {
              for i in $* ; do patch --batch --forward -p1 < $i ;done
            }
            patches ${openwrt}/target/linux/generic/backport-5.15/*.patch
            patches ${openwrt}/target/linux/generic/pending-5.15/*.patch
            patches ${openwrt}/target/linux/generic/hack-5.15/*.patch
            patches ${openwrt}/target/linux/ath79/patches-5.15/*.patch
          '';
          installPhase = ''
            mkdir -p $out
            cp -a . $out
          '';
        };
      };
    };
  kernel = rec {
    checkedConfig = {
      MIPS_ELF_APPENDED_DTB = "y";
      OF = "y";
      USE_OF = "y";
      ATH79 = "y";

      LIMINIX = "y";

      SERIAL_8250_CONSOLE = "y";
      SERIAL_8250 = "y";
      SERIAL_CORE_CONSOLE = "y";

      # need this to open console device at boot. dmesg goes from
      # [    0.272934] Warning: unable to open an initial console.
      # to
      # [    0.247413] printk: console [ttyS0] disabled
      # [     0.25200] 18020000.uart: ttyS0 at MMIO 0x1802000 (irq = 10, base_baud = 1562500) is a 16550A
      SERIAL_OF_PLATFORM = "y";

      CONSOLE_LOGLEVEL_DEFAULT = "8";
      CONSOLE_LOGLEVEL_QUIET = "4";

      # "empty" initramfs source should create an initial
      # filesystem that has a /dev/console node and not much
      # else.  Note that pid 1 is started *before* the root
      # filesystem is mounted and it expects /dev/console to
      # be present already
      BLK_DEV_INITRD = "n";

      NET = "y";
      NETDEVICES = "y";
      ETHERNET = "y";
      NET_VENDOR_ATHEROS = "y";
      AG71XX = "y";             # ethernet (qca,qca9530-eth)
      MFD_SYSCON = "y";         # ethernet (compatible "syscon")

    };
    config = {
      CPU_LITTLE_ENDIAN= "n";
      CPU_BIG_ENDIAN= "y";

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

      "MODULE_SIG" = "y";
      "MTD_CMDLINE_PARTS" = "y";
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