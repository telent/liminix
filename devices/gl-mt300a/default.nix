# GL.INet GL-MT300A

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

  description = ''
    WiFi on this device is provided by the rt2800soc module. It
    expects firmware to be present in the "factory" MTD partition, so
    - assuming we want to use the wireless - we need to build MTD
    support into the kernel even if we're using TFTP root
  '';

  module = { pkgs, config, ...}:
    let
      inherit (pkgs.liminix.networking) interface;
      inherit (pkgs) openwrt;
      mac80211 = pkgs.mac80211.override {
        drivers = ["rt2800soc"];
        klibBuild = config.outputs.kernel.modulesupport;
      };
     in {
      hardware = {
        defaultOutput = "tftpboot";
        loadAddress = "0x80000000";
        entryPoint  = "0x80000000";

        # Creating 5 MTD partitions on "spi0.0":
        # 0x000000000000-0x000000030000 : "u-boot"
        # 0x000000030000-0x000000040000 : "u-boot-env"
        # 0x000000040000-0x000000050000 : "factory"
        # 0x000000050000-0x000000fd0000 : "firmware"
        # 2 uimage-fw partitions found on MTD device firmware
        # Creating 2 MTD partitions on "firmware":
        # 0x000000000000-0x000000260000 : "kernel"
        # 0x000000260000-0x000000f80000 : "rootfs"

        flash = {
          address = "0xbc050000";
          size ="0xf80000";
          eraseBlockSize = "65536";
        };
        rootDevice = "/dev/mtdblock5";

        dts = {
          src = "${openwrt.src}/target/linux/ramips/dts/mt7620a_glinet_gl-mt300a.dts";
          includes = [
            "${openwrt.src}/target/linux/ramips/dts"
          ];
        };
        networkInterfaces = rec {
          # lan and wan ports are both behind a switch on eth0
          eth = interface { device = "eth0"; };
          lan = interface {
            type = "vlan";
            device = "eth0.1";
            link = "eth0";
            id = "1";
            dependencies = [eth];
          };
          wan = interface {
            type = "vlan";
            device = "eth0.2";
            id = "2";
            link = "eth0";
            dependencies = [eth];
          };
          wlan = interface {
            device = "wlan0";
            dependencies = [ mac80211 ];
          };
        };
      };
      boot.tftp = {
        loadAddress = "0x00A00000";
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

          SERIAL_8250_CONSOLE = "y";
          SERIAL_8250 = "y";
          SERIAL_CORE_CONSOLE = "y";
          SERIAL_OF_PLATFORM = "y";

          CONSOLE_LOGLEVEL_DEFAULT = "8";
          CONSOLE_LOGLEVEL_QUIET = "4";

          NET = "y";
          NETDEVICES = "y";
          ETHERNET = "y";
          NET_VENDOR_RALINK = "y";
          NET_RALINK_MDIO = "y";
          NET_RALINK_MDIO_MT7620 = "y";
          NET_RALINK_MT7620 = "y";

          SPI = "y";
          MTD_SPI_NOR = "y";
          SPI_MT7621 = "y"; # } probably don't need both of these
          SPI_RT2880 = "y"; # }
          SPI_MASTER= "y";
          SPI_MEM= "y";

          # both the ethernet ports on this device (lan and wan)
          # are behind a switch, so we need VLANs to do anything
          # useful with them

          VLAN_8021Q = "y";
          SWCONFIG = "y";
          SWPHY = "y";

          BRIDGE = "y";
          BRIDGE_VLAN_FILTERING = "y";
          BRIDGE_IGMP_SNOOPING = "y";

          MTD = "y";
          MTD_CMDLINE_PARTS = "y";
          MTD_BLOCK = "y";         # fix undefined ref to register_mtd_blktrans_devs

          CPU_LITTLE_ENDIAN = "y";

          CMDLINE_PARTITION = "y";
          EARLY_PRINTK = "y";

          NEW_LEDS = "y";
          LEDS_CLASS = "y";         # required by rt2x00lib

          PARTITION_ADVANCED = "y";
          PRINTK_TIME = "y";
          SQUASHFS = "y";
          SQUASHFS_XZ = "y";
        };
      };
    };
}
