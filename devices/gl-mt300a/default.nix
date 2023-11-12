# GL.iNet GL-MT300A

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
    GL.iNet GL-MT300A
    *****************

    The GL-MT300A is based on a MT7620 chipset.

    For flashing from U-Boot, the firmware partition is from
    0xbc050000 to 0xbcfd0000.

    WiFi on this device is provided by the rt2800soc module. It
    expects firmware to be present in the "factory" MTD partition, so
    - assuming we want to use the wireless - we need to build MTD
    support into the kernel even if we're using TFTP root.

    Installation
    ============

    The stock vendor firmware is a fork of OpenWrt, meaning that the
    binary created by :ref:`system-outputs-flashimage` can be flashed
    using the vendor web UI or the U-Boot emergency "unbrick" routine.

    For flashing from an existing Liminix system (we think) it
    is necessary to first boot into a :ref:`system-outputs-kexecboot`
    system, otherwise you'll be overwriting flash partitions while
    they're in use - and that might not end well.

    Vendor web page: https://www.gl-inet.com/products/gl-mt300a/

    OpenWrt web page: https://openwrt.org/toh/gl.inet/gl-mt300a

  '';

  module = { pkgs, config, lib, lim, ...}:
    let
      inherit (pkgs.liminix.networking) interface;
      inherit (pkgs) openwrt;
      mac80211 = pkgs.mac80211.override {
        drivers = ["rt2800soc"];
        klibBuild = config.system.outputs.kernel.modulesupport;
      };
    in {
      imports = [ ../../modules/arch/mipsel.nix ];
      hardware = {
        defaultOutput = "flashimage";
        loadAddress = lim.parseInt  "0x80000000";
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
        networkInterfaces =
          let
            inherit (config.system.service.network) link;
            inherit (config.system.service) vlan;
            inherit (pkgs.liminix.services) oneshot;
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
              down = "${pkgs.swconfig}/bin/swconfig dev switch0 set reset";
            };
          in rec {
            eth = link.build { ifname = "eth0"; };
            # lan and wan ports are both behind a switch on eth0
            lan = vlan.build {
              ifname = "eth0.1";
              primary = eth;
              vid = "1";
              dependencies =  [swconfig eth];
            };
            wan = vlan.build {
              ifname = "eth0.2";
              primary = eth;
              vid = "2";
              dependencies =  [swconfig eth];
            };
            wlan = link.build {
              ifname = "wlan0";
              dependencies = [ mac80211 ];
            };
          };
      };
      boot.tftp = {
        loadAddress = lim.parseInt "0x00A00000";
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
          ETHERNET = "y";
          NET_VENDOR_RALINK = "y";
          NET_RALINK_MDIO = "y";
          NET_RALINK_MDIO_MT7620 = "y";
          NET_RALINK_MT7620 = "y";
          SWPHY = "y";

          SPI = "y";
          MTD_SPI_NOR = "y";
          SPI_MT7621 = "y"; # } probably don't need both of these
          SPI_RT2880 = "y"; # }
          SPI_MASTER= "y";
          SPI_MEM= "y";

          MTD = "y";
          MTD_BLOCK = "y";         # fix undefined ref to register_mtd_blktrans_devs

          EARLY_PRINTK = "y";

          NEW_LEDS = "y";
          LEDS_CLASS = "y";         # required by rt2x00lib

          PRINTK_TIME = "y";
        } // lib.optionalAttrs (config.system.service ? vlan) {
          SWCONFIG = "y";
        };
      };
    };
}
