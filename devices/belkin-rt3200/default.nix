# This "device" generates images that can be used with the QEMU
# emulator. The default output is a directory containing separate
# kernel ("Image" format) and root filesystem (squashfs or jffs2)
# images
{
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
