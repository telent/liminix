{
  description = ''
    Belkin RT-3200 / Linksys E8450
    ******************************

    This device is based on a 64 bit Mediatek MT7622 ARM platform,
    and is "work in progress" in Liminix.

    The factory flash image contains ECC errors that make it incompatible
    with Liminix: you need to use the `OpenWrt UBI Installer <https://github.com/dangowrt/owrt-ubi-installer>`_ to rewrite the partition layout before
    you can flash Liminix onto it (or even use it with "tftpboot",
    if you want the wireless to work).

    - MediaTek MT7622BV (1350MHz)
    - 128MB NAND flash
    - 512MB	RAM
    - b/g/n wireless using MediaTek MT7622BV (MT7615E driver)
    - a/n/ac/ax wireless using  MediaTek MT7915E
  '';

  system = {
    crossSystem = {
      config = "aarch64-unknown-linux-musl";
    };
  };

  module = {pkgs, config, ... }: {
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
        COMMON_CLK_MT7622 = "y";
        COMMON_CLK_MT7622_ETHSYS = "y";
        COMMON_CLK_MT7622_HIFSYS = "y";
        COMMON_CLK_MT7622_AUDSYS = "y";

        REGMAP_MMIO = "y";
        CLKSRC_MMIO = "y";
        REGMAP = "y";

        MEDIATEK_GE_PHY = "y";
        # MEDIATEK_MT6577_AUXADC = "y";
        # MEDIATEK_WATCHDOG = "y";
        # MTD_NAND_ECC_MEDIATEK = "y";
        NET_MEDIATEK_SOC = "y";
        NET_MEDIATEK_SOC_WED = "y";
        NET_MEDIATEK_STAR_EMAC = "y"; # this enables REGMAP_MMIO
        NET_VENDOR_MEDIATEK = "y";
        PCIE_MEDIATEK = "y";
        # PWM_MEDIATEK = "y"; # seems to be ramips?

        BLOCK = "y"; # move this to base option
        NETDEVICES = "y";  # and this probably also

        MTD = "y";
        MTD_BLOCK = "y";

        MMC = "y";
        MMC_BLOCK = "y";
        MMC_CQHCI = "y";
        MMC_MTK = "y";

        PSTORE = "y";
        PSTORE_RAM = "y";
        PSTORE_CONSOLE = "y";
        PSTORE_DEFLATE_COMPRESS = "n";

        SERIAL_AMBA_PL011 = "y";
        SERIAL_AMBA_PL011_CONSOLE = "y";
      };
    };
    hardware =
      let
        openwrt = pkgs.openwrt;
        mac80211 =  pkgs.mac80211.override {
          drivers = ["mac80211_hwsim"];
          klibBuild = config.system.outputs.kernel.modulesupport;
        };
      in {
        defaultOutput = "flashimage";
        loadAddress = "0x41080000";
        entryPoint  = "0x41080000";
        rootDevice = "/dev/mtdblock0";
        dts = {
          src = "${openwrt.src}/target/linux/mediatek/dts/mt7622-linksys-e8450.dts";
          includes =  [
            "${openwrt.src}/target/linux/mediatek/dts"
            "${config.system.outputs.kernel.modulesupport}/arch/arm64/boot/dts/mediatek/"
          ];
        };

        flash.eraseBlockSize = "65536"; # c.f. pkgs/mips-vm/mips-vm.sh
        networkInterfaces =
          let inherit (config.system.service.network) link;
          in {
            wan = link.build { ifname = "eth0"; };
            lan = link.build { ifname = "eth1"; };

            wlan_24 = link.build {
              ifname = "wlan0";
              dependencies = [ mac80211 ];
            };
          };
      };

  };
}
