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

  module = {pkgs, config, lib, ... }:
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


        # probably don't need these
        # SERIAL_AMBA_PL011 = "y";
        # SERIAL_AMBA_PL011_CONSOLE = "y";
      };
    };
    boot.commandLine = [
      "console=ttyS0,115200"
    ];
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
          drivers = [ "mt7915e" "mt7615e"];
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
