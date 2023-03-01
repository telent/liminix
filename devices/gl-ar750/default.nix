
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

  description = ''
    GL.INet GL-AR750 "Creta" travel router
     - QCA9531 @650Mhz SoC
     - dual band wireless: IEEE 802.11a/b/g/n/ac
     - two 10/100Mbps LAN ports and one WAN
     - 128MB DDR2 RAM / 16MB  NOR Flash
     - "ath79" soc family
    https://www.gl-inet.com/products/gl-ar750/

    The GL-AR750 has two distinct sets of wifi hardware. The 2.4GHz
    radio is part of the QCA9531 SoC, i.e. it's on the same silicon as
    the CPU, the Ethernet, the USB etc. The device is connected to the
    host via AHB, the "Advanced High-Performance Bus" and it is
    supported in Linux using the ath9k driver. The 5GHz support, on the
    other hand, is provided by a QCA9887 PCIe (PCI embedded) WLAN chip:
    I haven't looked closely at the router innards to see if this is
    actually physically a separate board that could be unplugged, but
    as far as the Linux is concerned it behaves as one. This is
    supported by the ath10k driver.
  '';

  module = {pkgs, ... }:
    let
      openwrt = pkgs.pkgsBuildBuild.fetchFromGitHub {
        name = "openwrt-source";
        repo = "openwrt";
        owner = "openwrt";
        rev = "a5265497a4f6da158e95d6a450cb2cb6dc085cab";
        hash = "sha256-YYi4gkpLjbOK7bM2MGQjAyEBuXJ9JNXoz/JEmYf8xE8=";
      };
      firmwareBlobs = pkgs.pkgsBuildBuild.fetchFromGitHub {
        owner = "kvalo";
        repo = "ath10k-firmware";
        rev = "5d63529ffc6e24974bc7c45b28fd1c34573126eb";
        sha256 = "1bwpifrwl5mvsmbmc81k8l22hmkwk05v7xs8dxag7fgv2kd6lv2r";
      };
      firmware = pkgs.stdenv.mkDerivation {
        name = "regdb";
        phases = ["installPhase"];
        installPhase = ''
          mkdir -p $out/ath10k/QCA9887/hw1.0/
          cp ${pkgs.wireless-regdb}/lib/firmware/regulatory.db* $out/
          blobdir=${firmwareBlobs}/QCA9887/hw1.0
          cp $blobdir/10.2.4-1.0/firmware-5.bin_10.2.4-1.0-00047 $out/ath10k/QCA9887/hw1.0/firmware-5.bin
          # cp $ {./ar750-ath10k-cal.bin} $out/ath10k/cal-pci-0000:00:00.0.bin
          cp $blobdir/board.bin  $out/ath10k/QCA9887/hw1.0/
        '';
      };
      inherit (pkgs.pseudofile) dir symlink;
    in {
      device = {
        defaultOutput = "tftproot";
        loadAddress = "0x80060000";
        entryPoint  = "0x80060000";
        radios = ["ath9k" "ath10k_pci"];
      };
      boot.tftp = {
        loadAddress = "0x00A00000";
      };
      boot.dts = {
        src = "${openwrt}/target/linux/ath79/dts/qca9531_glinet_gl-ar750.dts";
        includes =  [
          "${openwrt}/target/linux/ath79/dts"
        ];
      };
      kernel = {
        src = pkgs.pkgsBuildBuild.fetchurl {
          name = "linux.tar.gz";
          url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
          hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
        };
        extraPatchPhase = ''
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
        config = {
          MIPS_ELF_APPENDED_DTB = "y";
          OF = "y";
          USE_OF = "y";
          ATH79 = "y";
          PCI = "y";

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
          AR8216_PHY = "y";         # eth1 is behind a switch

          MTD_SPI_NOR = "y";
          SPI_ATH79 = "y";      # these are copied from OpenWrt.
          SPI_MASTER= "y";      # At least one of them is necessary
          SPI_MEM= "y";
          SPI_AR934X= "y";
          SPI_BITBANG= "y";
          SPI_GPIO= "y";

          SPI = "y";
          MTD = "y";
          MTD_CMDLINE_PARTS = "y";
          MTD_BLOCK = "y";          # fix undefined ref to register_mtd_blktrans_devs
          CPU_BIG_ENDIAN= "y";

          # this is all copied from nixwrt ath79 config. Clearly not all
          # of it is device config, some of it is wifi config or
          # installation method config or ...

          CMDLINE_PARTITION = "y";
          EARLY_PRINTK = "y";

          PARTITION_ADVANCED = "y";
          PRINTK_TIME = "y";
          SQUASHFS = "y";
          SQUASHFS_XZ = "y";
        };
      };
    };
}
