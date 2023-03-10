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

  module = { pkgs, config, ...}:
    let
      inherit (pkgs.liminix.networking) interface;
      inherit (pkgs.liminix.services) oneshot;
      inherit (pkgs.pseudofile) dir symlink;

      openwrt = pkgs.fetchFromGitHub {
        name = "openwrt-source";
        repo = "openwrt";
        owner = "openwrt";
        rev = "a5265497a4f6da158e95d6a450cb2cb6dc085cab";
        hash = "sha256-YYi4gkpLjbOK7bM2MGQjAyEBuXJ9JNXoz/JEmYf8xE8=";
      };
      mac80211 = pkgs.mac80211.override {
        drivers = ["mt7603e"];
        klibBuild = config.outputs.kernel.modulesupport;
      };
      wlan_firmware = builtins.fetchurl {
        url = "https://github.com/openwrt/mt76/raw/f24b56f935392ca1d35fae5fd6e56ef9deda4aad/firmware/mt7628_e2.bin";
        sha256 = "sha256:1dkhfznmdz6s50kwc841x3wj0h6zg6icg5g2bim9pvg66as2vmh9";
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
        defaultOutput = "tftproot";
        loadAddress = "0x80000000";
        entryPoint  = "0x80000000";
        dts = {
          src = "${openwrt}/target/linux/ramips/dts/mt7628an_glinet_gl-mt300n-v2.dts";
          includes = [
            "${openwrt}/target/linux/ramips/dts"
          ];
        };
        networkInterfaces = rec {
          # lan and wan ports are both behind a switch on eth0
          eth =
            let swconfig = oneshot {
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
            in interface {
              device = "eth0";
              dependencies =  [swconfig];
            };
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
          CPU_LITTLE_ENDIAN= "y";

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

          MTD = "y";
          MTD_CMDLINE_PARTS = "y";
          MTD_BLOCK = "y";          # fix undefined ref to register_mtd_blktrans_dev

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

          # both the ethernet ports on this device (lan and wan)
          # are behind a switch, so we need VLANs to do anything
          # useful with them

          VLAN_8021Q = "y";
          SWCONFIG = "y";
          SWPHY = "y";

          BRIDGE = "y";
          BRIDGE_VLAN_FILTERING = "y";
          BRIDGE_IGMP_SNOOPING = "y";

          GPIOLIB="y";
          GPIO_MT7621 = "y";

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
