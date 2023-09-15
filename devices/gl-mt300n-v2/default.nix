# GL.INet GL-MT300N v2

{
  system = {
    crossSystem = {
      config = "mipsel-unknown-linux-musl";
      gcc = {
        abi = "32";
        arch = "mips32";          # maybe mips_24kc-
      };
    };
  };

  module = { pkgs, config, lib, ...}:
    let
      inherit (pkgs.liminix.networking) interface;
      inherit (pkgs.liminix.services) oneshot;
      inherit (pkgs.pseudofile) dir symlink;
      inherit (pkgs) openwrt;

      mac80211 = pkgs.mac80211.override {
        drivers = ["mt7603e"];
        klibBuild = config.system.outputs.kernel.modulesupport;
      };
      wlan_firmware = pkgs.fetchurl {
        url = "https://github.com/openwrt/mt76/raw/f24b56f935392ca1d35fae5fd6e56ef9deda4aad/firmware/mt7628_e2.bin";
        hash = "sha256:1dkhfznmdz6s50kwc841x3wj0h6zg6icg5g2bim9pvg66as2vmh9";
      };
    in {
      filesystem = dir {
        lib = dir {
          firmware = dir {
            "mt7628_e2.bin" = symlink wlan_firmware;
          };
        };
      };
      hardware = {
        defaultOutput = "flashimage";
        loadAddress = "0x80000000";
        entryPoint  = "0x80000000";

        flash = {
          address = "0xbc050000";
          size = "0xfb0000";
          eraseBlockSize = "65536";
        };
        rootDevice = "/dev/mtdblock5";

        dts = {
          src = "${openwrt.src}/target/linux/ramips/dts/mt7628an_glinet_gl-mt300n-v2.dts";
          includes = [
            "${openwrt.src}/target/linux/ramips/dts"
          ];
        };
        networkInterfaces =
          let
            inherit (config.system.service.network) link;
            inherit (config.system.service) vlan;
            swconfig = oneshot {
              name = "swconfig";
              up = ''
                PATH=${pkgs.swconfig}/bin:$PATH
                swconfig dev switch0 set reset
                swconfig dev switch0 set enable_vlan 1
                swconfig dev switch0 vlan 1 set ports '1 2 3 4 6t'
                swconfig dev switch0 vlan 2 set ports '0 6t'
                swconfig dev switch0 set apply
              '';
              down = "swconfig dev switch0 set reset";
            };
          in rec {
            eth = link.build { ifname = "eth0"; dependencies =  [swconfig]; };
            # lan and wan ports are both behind a switch on eth0
            lan = vlan.build {
              ifname = "eth0.1";
              primary = eth;
              vid = "1";
            };
            wan = vlan.build {
              ifname = "eth0.2";
              primary = eth;
              vid = "2";
            };
            wlan = link.build {
              ifname = "wlan0";
              dependencies = [ mac80211 ];
            };
          };
      };
      boot.tftp = {
        # 20MB seems to give enough room to uncompress the kernel
        # without anything getting trodden on. 10MB was too small
        loadAddress = "0x1400000";
      };

      kernel = {
        src = pkgs.fetchurl {
          name = "linux.tar.gz";
          url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
          hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
        };
        extraPatchPhase = ''
          ${openwrt.applyPatches.ramips}
        '';
        config = {
          MIPS_ELF_APPENDED_DTB = "y";
          OF = "y";
          USE_OF = "y";

          RALINK = "y";
          PCI = "y";
          SOC_MT7620 = "y";
          CPU_LITTLE_ENDIAN= "y";

          SERIAL_8250_CONSOLE = "y";
          SERIAL_8250 = "y";
          SERIAL_CORE_CONSOLE = "y";
          SERIAL_OF_PLATFORM = "y";

          CONSOLE_LOGLEVEL_DEFAULT = "8";
          CONSOLE_LOGLEVEL_QUIET = "4";

          MTD = "y";
          MTD_CMDLINE_PARTS = "y";
          MTD_BLOCK = "y";          # fix undefined ref to register_mtd_blktrans_dev

          SPI = "y";
          MTD_SPI_NOR = "y";
          SPI_MT7621 = "y";
          SPI_MASTER= "y";
          SPI_MEM= "y";

          REGULATOR = "y";
          REGULATOR_FIXED_VOLTAGE = "y";

          NET = "y";
          NETDEVICES = "y";
          ETHERNET = "y";

          PHYLIB = "y";
          AT803X_PHY="y";
          FIXED_PHY="y";
          GENERIC_PHY="y";
          NET_VENDOR_RALINK = "y";
          NET_RALINK_RT3050 = "y";
          NET_RALINK_SOC="y";
          SWPHY = "y";

          GPIOLIB="y";
          GPIO_MT7621 = "y";

          PHY_RALINK_USB = "y";

          CMDLINE_PARTITION = "y";
          EARLY_PRINTK = "y";

          PARTITION_ADVANCED = "y";
          PRINTK_TIME = "y";
        } // lib.optionalAttrs (config.system.service ? vlan) {
          SWCONFIG = "y";
        } // lib.optionalAttrs (config.system.service ? watchdog) {
          RALINK_WDT = "y";  # watchdog
          MT7621_WDT = "y";  # or it might be this one
        };
      };
    };
}
