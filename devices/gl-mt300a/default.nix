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
    expects firmware to be present in the "???" MTD partition, so -
    assuming we want to use the wireless - we need to build MTD
    support into the kernel even if we're using TFTP root
  '';

  module = { pkgs, config, ...}:
    let
      inherit (pkgs.liminix.networking) interface;
      openwrt = pkgs.fetchFromGitHub {
        name = "openwrt-source";
        repo = "openwrt";
        owner = "openwrt";
        rev = "a5265497a4f6da158e95d6a450cb2cb6dc085cab";
        hash = "sha256-YYi4gkpLjbOK7bM2MGQjAyEBuXJ9JNXoz/JEmYf8xE8=";
      };
      mac80211 = pkgs.mac80211.override {
        drivers = ["rt2800soc"];
        klibBuild = config.outputs.kernel.modulesupport;
      };
     in {
      hardware = {
        defaultOutput = "tftproot";
        loadAddress = "0x80000000";
        entryPoint  = "0x80000000";
        dts = {
          src = "${openwrt}/target/linux/ramips/dts/mt7620a_glinet_gl-mt300a.dts";
          includes = [
            "${openwrt}/target/linux/ramips/dts"
          ];
        };
        networkInterfaces = {
          # lan and wan ports are both behind a switch on eth0
          eth = interface { device = "eth0"; };
          lan = interface {
            type = "vlan";
            device = "eth0.1";
            link = "eth0";
            id = "1";
          };
          wan = interface {
            type = "vlan";
            device = "eth0.2";
            id = "2";
            link = "eth0";
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
          cp -av ${openwrt}/target/linux/generic/files/* .
          chmod -R u+w .
          cp -av ${openwrt}/target/linux/ramips/files/* .
          chmod -R u+w .
          patches() {
            for i in $* ; do patch --batch --forward -p1 < $i ;done
          }
          patches ${openwrt}/target/linux/generic/backport-5.15/*.patch
          patches ${openwrt}/target/linux/generic/pending-5.15/*.patch
          patches ${openwrt}/target/linux/generic/hack-5.15/*.patch
          patches ${openwrt}/target/linux/ramips/patches-5.15/*.patch
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

          # "empty" initramfs source should create an initial
          # filesystem that has a /dev/console node and not much
          # else.  Note that pid 1 is started *before* the root
          # filesystem is mounted and it expects /dev/console to
          # be present already
          BLK_DEV_INITRD = "n";

          NET = "y";
          NETDEVICES = "y";
          ETHERNET = "y";
          NET_RALINK_MDIO = "y";
          NET_RALINK_MDIO_MT7620 = "y";
          NET_RALINK_MT7620 = "y";

          SPI = "y";
          MTD_SPI_NOR = "y";
          SPI_MT7621 = "y"; # } probabyl don't need both of these
          SPI_RT2880 = "y"; # }
          SPI_MASTER= "y";
          SPI_MEM= "y";

          # both the ethernet ports on this device (lan and wan)
          # are behind a switch, so we need VLANs to do anything
          # useful with them

          VLAN_8021Q = "y";
          SWCONFIG = "y";
          SWPHY = "y";

          BRIDGE_VLAN_FILTERING = "y";
          BRIDGE_IGMP_SNOOPING = "y";
          NET_VENDOR_RALINK = "y";

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
