{
  description = ''
    Belkin RT-3200 / Linksys E8450
    ******************************

    This device is based on a 64 bit Mediatek MT7622 ARM platform,
    and is "work in progress" in Liminix.

    .. note:: The factory flash image contains ECC errors that make it
              incompatible with Liminix: you need to use the `OpenWrt
              UBI Installer <https://github.com/dangowrt/owrt-ubi-installer>`_ to
              rewrite the partition layout before you can flash
              Liminix onto it (or even use it with
              :ref:`system-outputs-tftpboot`, if you want the wireless
              to work).

    Hardware summary
    ================

    - MediaTek MT7622BV (1350MHz)
    - 128MB NAND flash
    - 512MB	RAM
    - b/g/n wireless using MediaTek MT7622BV (MT7615E driver)
    - a/n/ac/ax wireless using  MediaTek MT7915E


    Installation
    ============

    Installation is currently a manual process (you need a :ref:`serial <serial>` conection and
    TFTP) following the instructions at :ref:`system-outputs-ubimage`

'';

  system = {
    crossSystem = {
      config = "aarch64-unknown-linux-musl";
    };
  };

  module = {pkgs, config, lib, lim, ... }:
    let firmware = pkgs.stdenv.mkDerivation {
          name = "wlan-firmware";
          phases = ["installPhase"];
          installPhase = ''
            mkdir $out
            cp ${pkgs.linux-firmware}/lib/firmware/mediatek/{mt7915,mt7615,mt7622}* $out
          '';
        };
    in {
    imports = [ ../../modules/arch/aarch64.nix ];
    kernel = {
      src = pkgs.pkgsBuildBuild.fetchurl {
        name = "linux.tar.gz";
        url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
        hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
      };
      extraPatchPhase = ''
          ${pkgs.openwrt.applyPatches.mediatek}
      '';
      config = {
        PCI = "y";
        ARCH_MEDIATEK = "y";
        # ARM_MEDIATEK_CPUFREQ = "y";

        # needed for "Cannot find regmap for /infracfg@10000000"
        MFD_SYSCON = "y";
        MTK_INFRACFG = "y";

        MTK_PMIC_WRAP = "y";
        MTK_EFUSE="y";
        # MTK_HSDMA="y";
        MTK_SCPSYS="y";
        MTK_SCPSYS_PM_DOMAINS="y";
        # MTK_THERMAL="y";
        MTK_TIMER="y";

        COMMON_CLK_MT7622 = "y";
        COMMON_CLK_MT7622_ETHSYS = "y";
        COMMON_CLK_MT7622_HIFSYS = "y";
        COMMON_CLK_MT7622_AUDSYS = "y";
        PM_CLK="y";

        REGMAP_MMIO = "y";
        CLKSRC_MMIO = "y";
        REGMAP = "y";

        MEDIATEK_GE_PHY = "y";
        # MEDIATEK_MT6577_AUXADC = "y";
        # MEDIATEK_WATCHDOG = "y";
        NET_MEDIATEK_SOC = "y";
        NET_MEDIATEK_SOC_WED = "y";
        NET_MEDIATEK_STAR_EMAC = "y"; # this enables REGMAP_MMIO
        NET_VENDOR_MEDIATEK = "y";
        PCIE_MEDIATEK = "y";

        BLOCK = "y"; # move this to base option

        SPI_MASTER = "y";
        SPI = "y";
        SPI_MEM="y";
        SPI_MTK_NOR="y";
        SPI_MTK_SNFI = "y";

        MTD = "y";
        MTD_BLOCK = "y";
        MTD_RAW_NAND = "y";
        MTD_NAND_MTK = "y";
        MTD_NAND_MTK_BMT = "y";      # Bad-block Management Table
        MTD_NAND_ECC_MEDIATEK= "y";
        MTD_NAND_ECC_SW_HAMMING= "y";
        MTD_SPI_NAND= "y";
        MTD_OF_PARTS = "y";
        MTD_NAND_CORE= "y";
        MTD_SPI_NOR= "y";
        MTD_SPLIT_FIRMWARE= "y";
        MTD_SPLIT_FIT_FW= "y";


        MMC = "y";
        MMC_BLOCK = "y";
        MMC_CQHCI = "y";
        MMC_MTK = "y";

        # Distributed Switch Architecture is needed
        # to make the ethernet ports visible
        NET_DSA="y";
        NET_DSA_MT7530="y";
        NET_DSA_TAG_MTK="y";

        PSTORE = "y";
        PSTORE_RAM = "y";
        PSTORE_CONSOLE = "y";
        PSTORE_DEFLATE_COMPRESS = "n";

        SERIAL_8250 = "y";
        SERIAL_8250_CONSOLE = "y";
        SERIAL_8250_MT6577="y";
        # SERIAL_8250_NR_UARTS="3";
        # SERIAL_8250_RUNTIME_UARTS="3";
        SERIAL_OF_PLATFORM="y";
      };
    };
    boot = {
      commandLine = [ "console=ttyS0,115200" ];
      tftp.loadAddress = lim.parseInt "0x4007ff28";
      imageFormat = "fit";
    };
    filesystem =
      let inherit (pkgs.pseudofile) dir symlink;
           in
             dir {
               lib = dir {
                 firmware = dir {
                   mediatek = symlink firmware;
                 };
               };
             };

    hardware =
      let
        openwrt = pkgs.openwrt;
        mac80211 =  pkgs.mac80211.override {
          drivers = [
            "mt7615e"
            "mt7915e"
          ];
          klibBuild = config.system.outputs.kernel.modulesupport;
        };
      in {
        ubi = {
          minIOSize = "2048";
          eraseBlockSize = "126976";
          maxLEBcount = "1024"; # guessing
        };

        defaultOutput = "ubimage";
        # the kernel expects this to be on a 2MB boundary. U-Boot
        # (I don't know why) has a default of 0x41080000, which isn't.
        # We put it at the 32MB mark so that tftpboot can put its rootfs
        # image and DTB underneath, but maybe this is a terrible waste of
        # RAM unless the kernel is able to reuse it later. Oh well
        loadAddress = lim.parseInt "0x42000000";
        entryPoint = lim.parseInt "0x42000000";
        rootDevice = "ubi0:liminix";
        dts = {
          src = "${openwrt.src}/target/linux/mediatek/dts/mt7622-linksys-e8450-ubi.dts";
          includes =  [
            "${openwrt.src}/target/linux/mediatek/dts"
            "${config.system.outputs.kernel.modulesupport}/arch/arm64/boot/dts/mediatek/"
          ];
        };

        # - 0x000000000000-0x000008000000 : "spi-nand0"
        #         - 0x000000000000-0x000000080000 : "bl2"
        #         - 0x000000080000-0x0000001c0000 : "fip"
        #         - 0x0000001c0000-0x0000002c0000 : "factory"
        #         - 0x0000002c0000-0x000000300000 : "reserved"
        #         - 0x000000300000-0x000008000000 : "ubi"

        networkInterfaces =
          let
            inherit (config.system.service.network) link;
            inherit (config.system.service) bridge;
          in rec {
            wan = link.build { ifname = "wan"; };
            lan1 = link.build { ifname = "lan1"; };
            lan2 = link.build { ifname = "lan2"; };
            lan3 = link.build { ifname = "lan3"; };
            lan4 = link.build { ifname = "lan4"; };
            lan = lan3;

            wlan = link.build {
              ifname = "wlan0";
              dependencies = [ mac80211 ];
            };
            wlan5 = link.build {
              ifname = "wlan1";
              dependencies = [ mac80211 ];
            };
          };
      };

  };
}
