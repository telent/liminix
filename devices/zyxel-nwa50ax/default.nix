{
  system = {
    crossSystem = {
      config = "mipsel-unknown-linux-musl";
      gcc = {
        abi = "32";
        arch = "mips32";          # mips32r2?
      };
    };
  };

  description = ''
    Zyxel NWA50AX
    ********************

    Zyxel NWA50AX is quite close to the GL-MT300N-v2 "Mango" device, but it is based on the MT7621
    chipset instead of the MT7628.

    Installation
    ============

    Wow, this device is a handful.

    The stock vendor firmware is a downstream fork of U-Boot (insert link to source code)
    with restricted boot commands. Fortunately, OpenWrt folks figured out trivial command injections,
    so you can use most of the OpenWrt commands without trouble by just command injecting
    atns, atna or atnf, e.g. atns "; $real_command".

    From factory web UI, this has not been tested yet.
    From serial, you have two choices:

    - boot from an existing Liminix system, e.g. TFTPBOOT image.
    - boot from an OpenWrt system, i.e. follow OpenWrt steps.

    Once you are in a Linux system, understand that this device has A/B boot.

    OpenWrt provides you with `zyxel-bootconfig` to set/unset the image status and choice.
    The kernel is booted with `bootImage=<number>` which tells you which slot are you on.

    You should find yourself with 10ish MTD partitions, the most interesting ones are two:

    - firmware: 40MB
    - firmware_1: 40MB

    In the current setup, they are split further into kernel (8MB) and ubi (32MB).

    You will write the FIT uImage in the kernel MTD partition directly, via `mtd write kernel.uimage /dev/mtd4`
    (if `/dev/mtd4` is the kernel MTD partition) or `flashcp` can be used similarly.

    Then, you will install the UBI image, via `ubiformat -f ubi.image /dev/mtd5` (if `/dev/mtd4` was your kernel MTD partition, 5 must be the UBI).

    Once you are done, you will have to reboot and modify your bootargs in U-Boot
    because they are currently overridden.

    It is enough to do:
    atns "; setenv bootargs 'liminix console=ttyS0,115200 panic=10 oops=panic init=/bin/init loglevel=8 fw_devlink=off ubi.mtd=ubi root=ubi0:rootfs rootfstype=ubifs'"
    atns "; saveenv"

    Once you are done, you can enjoy booting on slot A unattended for now. To make use of the A/B feature, this is a TODO :).
    Upgrades are TODO too.

    Vendor web page: https://www.zyxel.com/fr/fr/products/wireless/ax1800-wifi-6-dual-radio-nebulaflex-access-point-nwa50ax

    OpenWrt web page: https://openwrt.org/inbox/toh/zyxel/nwa50ax
    OpenWrt tech data: https://openwrt.org/toh/hwdata/zyxel/zyxel_nwa50ax

  '';

  module = { pkgs, config, lib, lim, ...}:
    let
      inherit (pkgs.liminix.networking) interface;
      inherit (pkgs.liminix.services) oneshot;
      inherit (pkgs.pseudofile) dir symlink;
      inherit (pkgs) openwrt;

      mac80211 = pkgs.mac80211.override {
        drivers = [ "mt7915e" ];
        klibBuild = config.system.outputs.kernel.modulesupport;
      };
      wlan_firmware = pkgs.fetchurl {
        url = "https://github.com/openwrt/mt76/raw/2afc7285f75dca5a0583fd917285bf33f1429cc6/firmware/mt7915_wa.bin";
        hash = "sha256-wooyefzb0i8640+lwq3vNhcBXRFCtGuo+jiL7afZaKA=";
      };
      wlan_firmware' = pkgs.fetchurl {
        url = "https://github.com/openwrt/mt76/raw/2afc7285f75dca5a0583fd917285bf33f1429cc6/firmware/mt7915_wm.bin";
        hash = "sha256-k62nQewRuKjBLd5R3RxU4F74YKnQx5zr6gqMMImqVQw=";
      };
      wlan_firmware'' = pkgs.fetchurl {
        url = "https://github.com/openwrt/mt76/raw/2afc7285f75dca5a0583fd917285bf33f1429cc6/firmware/mt7915_rom_patch.bin";
        hash = "sha256-ifriAjWzFACrxVWCANZpUaEZgB/0pdbhnTVQytx6ddg=";
      };
    in {
      imports = [ 
        ../../modules/arch/mipsel.nix
        ../../modules/outputs/tftpboot.nix
        ../../modules/outputs/zyxel-nwa-fit.nix
      ];

      filesystem = dir {
        lib = dir {
          firmware = dir {
            mediatek = dir {
              "mt7915_wa.bin" = symlink wlan_firmware;
              "mt7915_wm.bin" = symlink wlan_firmware';
              "mt7915_rom_patch.bin" = symlink wlan_firmware'';
            };
          };
        };
      };

      rootfsType = "ubifs";
      hardware = {
        # Taken from OpenWRT
        # root@OpenWrt:/# ubinfo /dev/ubi0
        # ubi0
        # Volumes count:                           2
        # Logical eraseblock size:                 126976 bytes, 124.0 KiB
        # Total amount of logical eraseblocks:     256 (32505856 bytes, 31.0 MiB)
        # Amount of available logical eraseblocks: 0 (0 bytes)
        # Maximum count of volumes                 128
        # Count of bad physical eraseblocks:       0
        # Count of reserved physical eraseblocks:  19
        # Current maximum erase counter value:     2
        # Minimum input/output unit size:          2048 bytes
        # Character device major/minor:            250:0
        # Present volumes:                         0, 1
        ubi = {
          minIOSize = "2048";
          logicalEraseBlockSize = "126976";
          physicalEraseBlockSize = "128KiB";
          maxLEBcount = "256";
        };

        # This is a FIT containing a kernel padded and
        # a UBI volume rootfs.
        defaultOutput = "zyxel-nwa-fit";
        loadAddress = lim.parseInt "0x80001000";
        entryPoint = lim.parseInt "0x80001000";
        # Aligned on 2kb.
        alignment = 2048;

        flash = {
          address = lim.parseInt "0xbc050000";
          size = lim.parseInt "0xfb0000";
          eraseBlockSize = 65536;
        };
        rootDevice = "ubi0:rootfs";

        dts = {
          src = "${openwrt.src}/target/linux/ramips/dts/mt7621_zyxel_nwa50ax.dts";
          includes = [
            "${openwrt.src}/target/linux/ramips/dts"
          ];
        };
        networkInterfaces =
          let
            inherit (config.system.service.network) link;
          in {
            eth = link.build { ifname = "eth0"; };
            lan = link.build { ifname = "lan"; };
            wlan0 = link.build {
              ifname = "wlan0";
              dependencies = [ mac80211 ];
            };
            wlan1 = link.build {
              ifname = "wlan1";
              dependencies = [ mac80211 ];
            };
          };
      };
      boot = {
        # Critical because NWA50AX will extend your cmdline with the image number booted.
        # and some bootloader version.
        # You don't want to find yourself being overridden.
        commandLineDtbNode = "bootargs-override";

        imageFormat = "fit";
        tftp = {
          # 5MB is nice.
          freeSpaceBytes = 5 * 1024 * 1024;
          loadAddress = lim.parseInt "0x2000000";
        };
      };

      #  DEVICE_VENDOR := ZyXEL
      #  KERNEL_SIZE := 8192k
      #  DEVICE_PACKAGES := kmod-mt7915-firmware zyxel-bootconfig
      #  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
      #  IMAGES += factory.bin ramboot-factory.bin
      #  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | zyxel-nwa-fit
      #  IMAGE/ramboot-factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi

      kernel = {
        src = pkgs.fetchurl {
          name = "linux.tar.gz";
          url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.137.tar.gz";
          hash = "sha256-PkdzUKZ0IpBiWe/RS70J76JKnBFzRblWcKlaIFNxnHQ=";
        };
        extraPatchPhase = ''
          ${openwrt.applyPatches.ramips}

        '';
        config = {

          RALINK = "y";
          PCI = "y";
          PHY_MT7621_PCI = "y";
          PCIE_MT7621 = "y";
          SOC_MT7621 = "y";
          CLK_MT7621 = "y";
          CLOCKSOURCE_WATCHDOG = "y";

          SERIAL_8250_CONSOLE = "y";
          SERIAL_8250 = "y";
          SERIAL_CORE_CONSOLE = "y";
          SERIAL_OF_PLATFORM = "y";
          SERIAL_8250_NR_UARTS = "3";
          SERIAL_8250_RUNTIME_UARTS = "3";
          SERIAL_MCTRL_GPIO = "y";

          CONSOLE_LOGLEVEL_DEFAULT = "8";
          CONSOLE_LOGLEVEL_QUIET = "4";

          # MTD_UBI_BEB_LIMIT = "20";
          # MTD_UBI_WL_THRESHOLD = "4096";

          MTD = "y";
          MTD_BLOCK = "y";          # fix undefined ref to register_mtd_blktrans_dev
          MTD_RAW_NAND = "y";
          MTD_NAND_MT7621 = "y";
          MTD_NAND_MTK_BMT = "y";      # Bad-block Management Table
          MTD_NAND_ECC_SW_HAMMING= "y";
          MTD_SPI_NAND= "y";
          MTD_OF_PARTS = "y";
          MTD_NAND_CORE= "y";
          MTD_SPLIT_FIRMWARE= "y";
          MTD_SPLIT_FIT_FW= "y";

          PINCTRL = "y";
          PINCTRL_MT7621 = "y";

          I2C = "y";
          I2C_MT7621 = "y";

          SPI = "y";
          MTD_SPI_NOR = "y";
          SPI_MT7621 = "y";
          SPI_MASTER = "y";
          SPI_MEM = "y";

          REGULATOR = "y";
          REGULATOR_FIXED_VOLTAGE = "y";
          RESET_CONTROLLER = "y";
          POWER_RESET = "y";
          POWER_RESET_GPIO = "y";
          POWER_SUPPLY = "y";
          LED_TRIGGER_PHY = "y";

          PCI_DISABLE_COMMON_QUIRKS = "y";
          PCI_DOMAINS = "y";
          PCI_DOMAINS_GENERIC = "y";
          PCI_DRIVERS_GENERIC = "y";
          PCS_MTK_LYNXI = "y";

          SOC_BUS = "y";

          NET = "y";
          ETHERNET = "y";
          WLAN = "y";

          PHYLIB = "y";
          AT803X_PHY = "y";
          FIXED_PHY = "y";
          GENERIC_PHY = "y";
          NET_DSA = "y";
          NET_DSA_MT7530 = "y";
          NET_DSA_MT7530_MDIO = "y";
          NET_DSA_TAG_MTK = "y";
          NET_MEDIATEK_SOC = "y";
          NET_SWITCHDEV = "y";
          NET_VENDOR_MEDIATEK = "y";

          SWPHY = "y";

          GPIOLIB = "y";
          GPIO_MT7621 = "y";
          OF_GPIO = "y";

          EARLY_PRINTK = "y";

          NEW_LEDS = "y";
          LEDS_TRIGGERS = "y";
          LEDS_CLASS = "y";         # required by rt2x00lib
          LEDS_CLASS_MULTICOLOR = "y";
          LEDS_BRIGHTNESS_HW_CHANGED = "y";

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
