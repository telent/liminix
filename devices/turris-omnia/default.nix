{
  description = ''
    Turris Omnia
    ************
  '';

  system = {
    crossSystem = {
      config = "armv7l-unknown-linux-musleabihf";
    };
  };

  module = {pkgs, config, lib, lim, ... }:
    let openwrt = pkgs.openwrt; in {
    imports = [ ../../modules/arch/arm.nix ];
    kernel = {
      src = pkgs.pkgsBuildBuild.fetchurl {
        name = "linux.tar.gz";
        url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
        hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
      };
      extraPatchPhase = ''
          ${pkgs.openwrt.applyPatches.mvebu}
      '';
      config = {
        PCI = "y";
        OF = "y";
        MEMORY = "y"; # for MVEBU_DEVBUS
        DMADEVICES = "y"; # for MV_XOR
        CPU_V7 = "y";
        ARCH_MULTIPLATFORM = "y";
        ARCH_MVEBU = "y";
        ARCH_MULTI_V7= "y";
        PCI_MVEBU = "y";
        AHCI_MVEBU = "y";
        MACH_ARMADA_38X = "y";
        SMP = "y";
	      # this is disabled for the moment because it relies on a GCC
        # plugin that requires gmp.h to build, and I can't see right now
        # how to confgure it to find gmp
        STACKPROTECTOR_PER_TASK = "n";
        NR_CPUS = "4";
        VFP = "y";
        NEON= "y";

        # WARNING: unmet direct dependencies detected for ARCH_WANT_LIBATA_LEDS
        ATA = "y";

        # switch is DSA
        # CONFIG_NET_DSA_MV88E6060=y
        #   CONFIG_NET_DSA_MV88E6XXX=y
        #     CONFIG_NET_DSA_MV88E6XXX_GLOBAL2=y

        #         CONFIG_REGMAP=y
        # CONFIG_REGMAP_I2C=y
        # CONFIG_REGMAP_SPI=y
        # CONFIG_REGMAP_MMIO=y

        PSTORE = "y";
        PSTORE_RAM = "y";
        PSTORE_CONSOLE = "y";
        PSTORE_DEFLATE_COMPRESS = "n";

        SERIAL_8250 = "y";
        SERIAL_8250_CONSOLE = "y";
        SERIAL_OF_PLATFORM="y";
        SERIAL_MVEBU_UART = "y";
        SERIAL_MVEBU_CONSOLE = "y";

        SERIAL_8250_DMA= "y";
        SERIAL_8250_DW= "y";
        SERIAL_8250_EXTENDED= "y";
        SERIAL_8250_MANY_PORTS= "y";
        SERIAL_8250_SHARE_IRQ= "y";
        OF_ADDRESS= "y";
        OF_MDIO= "y";

        WATCHDOG = "y";        # watchdog is enabled by u-boot
        ORION_WATCHDOG = "y";  # so is non-optional to keep feeding

        MVEBU_DEVBUS = "y"; # "Device Bus controller ...  flash devices such as NOR, NAND, SRAM, and FPGA"
        MVMDIO = "y";
        MVNETA = "y";
        MVNETA_BM = "y";
        MVNETA_BM_ENABLE = "y";
        MVPP2 = "y";
        MV_XOR = "y";
      };
    };

    boot = {
      commandLine = [
        "console=ttyS0,115200"
        "pcie_aspm=off" # ath9k pci incompatible with PCIe ASPM
      ];
      imageFormat = "fit";
    };
    filesystem =
      let
        inherit (pkgs.pseudofile) dir symlink;
        firmware = pkgs.stdenv.mkDerivation {
          name = "wlan-firmware";
          phases = ["installPhase"];
          installPhase = ''
            mkdir $out
            cp -r ${pkgs.linux-firmware}/lib/firmware/ath10k/QCA988X $out
          '';
        };
        in dir {
          lib = dir {
            firmware = dir {
              ath10k = symlink firmware;
            };
          };
        };

    hardware = let
      mac80211 = pkgs.mac80211.override {
        drivers = ["ath9k_pci" "ath10k_pci"];
        klibBuild = config.system.outputs.kernel.modulesupport;
      };
      in {
        defaultOutput = "flashimage";
        loadAddress = lim.parseInt "0x00008000";
        entryPoint = lim.parseInt "0x00008000";
        rootDevice = "/dev/mtdblock0";
        dts = {
          src = "${config.system.outputs.kernel.modulesupport}/arch/arm/boot/dts/armada-385-turris-omnia.dts";
          includes =  [
            "${config.system.outputs.kernel.modulesupport}/arch/arm/boot/dts/"
          ];
        };
        flash.eraseBlockSize = 65536; # only used for tftpboot
        networkInterfaces =
          let
            inherit (config.system.service.network) link;
            inherit (config.system.service) bridge;
          in rec {
            lan = link.build { ifname = "eth0"; };
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
