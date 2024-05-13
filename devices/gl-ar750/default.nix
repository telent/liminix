{
  system = {
    crossSystem = {
      config = "mips-unknown-linux-musl";
      gcc = {
        abi = "32";
        arch = "24kc";          # maybe mips_24kc-
      };
    };
  };

  description = ''
    GL.iNet GL-AR750
    ****************

    Hardware summary
    ================

    The GL-AR750 "Creta" travel router features:

     - QCA9531 @650Mhz SoC
     - dual band wireless: IEEE 802.11a/b/g/n/ac
     - two 10/100Mbps LAN ports and one WAN
     - 128MB DDR2 RAM
     - 16MB NOR Flash
     - supported in OpenWrt by the "ath79" SoC family

    The GL-AR750 has two distinct sets of wifi hardware. The 2.4GHz
    radio is part of the QCA9531 SoC, i.e. it's on the same silicon as
    the CPU, the Ethernet, the USB etc. The device is connected to the
    host via `AHB <https://en.wikipedia.org/wiki/Advanced_Microcontroller_Bus_Architecture>`_ and it is
    supported in Linux using the ath9k driver. 5GHz wifi
    is provided by a QCA9887 PCIe (PCI embedded) WLAN chip,
    supported by the ath10k driver.

    Installation
    ============

    As with many GL.iNet devices, the stock vendor firmware
    is a fork of OpenWrt, meaning that the binary created by
    :ref:`system-outputs-mtdimage` can be flashed using the
    vendor web UI or the U-Boot emergency "unbrick" routine.

    For flashing from an existing Liminix system (we believe that) it
    is necessary to first boot into a :ref:`system-outputs-kexecboot`
    system, otherwise you'll be overwriting flash partitions while
    they're in use - and that might not end well.

    Vendor web page: https://www.gl-inet.com/products/gl-ar750/

    OpenWrt web page: https://openwrt.org/toh/gl.inet/gl-ar750

  '';

  module = {pkgs, config, lim, ... }:
    let
      openwrt = pkgs.openwrt;
      firmwareBlobs = pkgs.pkgsBuildBuild.fetchFromGitHub {
        owner = "kvalo";
        repo = "ath10k-firmware";
        rev = "5d63529ffc6e24974bc7c45b28fd1c34573126eb";
        sha256 = "1bwpifrwl5mvsmbmc81k8l22hmkwk05v7xs8dxag7fgv2kd6lv2r";
      };
      firmware = pkgs.stdenv.mkDerivation {
        name = "wlan-firmware";
        phases = ["installPhase"];
        installPhase = ''
          mkdir -p $out/ath10k/QCA9887/hw1.0/
          blobdir=${firmwareBlobs}/QCA9887/hw1.0
          cp $blobdir/10.2.4-1.0/firmware-5.bin_10.2.4-1.0-00047 $out/ath10k/QCA9887/hw1.0/firmware-5.bin
          cp $blobdir/board.bin  $out/ath10k/QCA9887/hw1.0/
        '';
      };
      mac80211 = pkgs.kmodloader.override {
        targets = ["ath9k" "ath10k_pci"];
        inherit (config.system.outputs) kernel;
        dependencies = [ ath10k_cal_data ];
      };
      ath10k_cal_data =
        let
          offset = lim.parseInt "0x5000";
          size = lim.parseInt "0x844";
        in pkgs.liminix.services.oneshot rec  {
          name = "ath10k_cal_data";
          up = ''
            part=$(basename $(dirname $(grep -l art /sys/class/mtd/*/name)))
            echo ART partition is ''${part-unset}
            test -n "$part" || exit 1
            (in_outputs ${name}
             dd if=/dev/$part of=data iflag=skip_bytes,fullblock bs=${toString size} skip=${toString offset} count=1
            )
        '';
      };
      inherit (pkgs.pseudofile) dir symlink;
      inherit (pkgs.liminix.networking) interface;
    in {
      imports = [
        ../../modules/network
        ../../modules/arch/mipseb.nix
        ../../modules/outputs/tftpboot.nix
        ../../modules/outputs/mtdimage.nix
        ../../modules/outputs/jffs2.nix
      ];

      programs.busybox.options = {
        FEATURE_DD_IBS_OBS = "y"; # ath10k_cal_data needs skip_bytes,fullblock
      };
      hardware = {
        defaultOutput = "mtdimage";
        loadAddress = lim.parseInt "0x80060000";
        entryPoint = lim.parseInt "0x80060000";
        flash = {
          address = lim.parseInt "0x9F060000";
          size = lim.parseInt "0xfa0000";
          eraseBlockSize = 65536;
        };
        rootDevice = "/dev/mtdblock5";
        dts = {
          src = "${openwrt.src}/target/linux/ath79/dts/qca9531_glinet_gl-ar750.dts";
          includes =  [
            "${openwrt.src}/target/linux/ath79/dts"
          ];
        };

        networkInterfaces =
          let inherit (config.system.service.network) link;
          in {
            lan = link.build {
              ifname = "lan";
              devpath = "/devices/platform/ahb/19000000.eth";
            };
            wan = link.build {
              ifname = "wan";
              devpath = "/devices/platform/ahb/1a000000.eth";
            };
            wlan = link.build {
              ifname = "wlan0";
              dependencies = [ mac80211 ];
            };
            wlan5 = link.build {
              ifname = "wlan1";
              dependencies = [ ath10k_cal_data mac80211  ];
            };
          };
      };
      filesystem = dir {
        lib = dir {
          firmware = dir {
            ath10k = dir {
              QCA9887 = symlink "${firmware}/ath10k/QCA9887";
              "cal-pci-0000:00:00.0.bin" = symlink "${ath10k_cal_data}/.outputs/data";
            };
          };
        };
      };
      boot.tftp = {
        loadAddress = lim.parseInt "0x00A00000";
        appendDTB = true;
      };
      kernel = {
        src = pkgs.pkgsBuildBuild.fetchurl {
          name = "linux.tar.gz";
          url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.137.tar.gz";
          hash = "sha256-PkdzUKZ0IpBiWe/RS70J76JKnBFzRblWcKlaIFNxnHQ=";
        };

        # Mainline linux 5.19 doesn't have device-tree support for
        # this device or even for the SoC, so we use the extensive
        # OpenWrt kernel patches
        extraPatchPhase = ''
          ${openwrt.applyPatches.ath79}
          sed -i.bak -e '\,include <linux/hw_random.h>,a #include <linux/gpio/driver.h>'  drivers/net/wireless/ath/ath9k/ath9k.h # context reqd for next patch
          patch -p1 <  ${openwrt.src}/package/kernel/mac80211/patches/ath9k/552-ath9k-ahb_of.patch
        '';

        config = {
          ATH79 = "y";
          PCI = "y";
          PCI_AR724X = "y";

          SERIAL_8250_CONSOLE = "y";
          SERIAL_8250 = "y";
          SERIAL_CORE_CONSOLE = "y";

          # need this to open console device at boot. dmesg goes from
          # [    0.272934] Warning: unable to open an initial console.
          # to
          # [    0.247413] printk: console [ttyS0] disabled
          # [     0.25200] 18020000.uart: ttyS0 at MMIO 0x1802000 (irq = 10, base_baud = 1562500) is a 16550A
          SERIAL_OF_PLATFORM = "y";

          CONSOLE_LOGLEVEL_DEFAULT = "8";
          CONSOLE_LOGLEVEL_QUIET = "4";

          NET = "y";
          ETHERNET = "y";
          NET_VENDOR_ATHEROS = "y";
          AG71XX = "y";             # ethernet (qca,qca9530-eth)
          MFD_SYSCON = "y";         # ethernet (compatible "syscon")
          AR8216_PHY = "y";         # eth1 is behind a switch

          MTD_SPI_NOR = "y";

          SPI_ATH79 = "y";      # these are copied from OpenWrt.
          SPI_MASTER= "y";      # At least one of them is necessary
          SPI_MEM= "y";
          SPI_AR934X= "y";
          SPI_BITBANG= "y";
          SPI_GPIO= "y";

          GPIO_ATH79 = "y";
          GPIOLIB = "y";
          EXPERT="y";
          GPIO_SYSFS = "y"; # required by patches-5.15/0004-phy-add-ath79-usb-phys.patch
          OF_GPIO = "y";
          SYSFS = "y";
          SPI = "y";
          MTD = "y";
          MTD_BLOCK = "y";          # fix undefined ref to register_mtd_blktrans_devs

          WATCHDOG = "y";
          ATH79_WDT = "y";  # watchdog timer

          EARLY_PRINTK = "y";

          PRINTK_TIME = "y";
        };
        conditionalConfig = {
          WLAN = {
            WLAN_VENDOR_ATH = "y";
            ATH_COMMON = "m";
            ATH9K = "m";
            ATH9K_AHB = "y";
            ATH10K = "m";
            ATH10K_PCI = "m";
            ATH10K_DEBUG = "y";
          };
        };
      };
    };
}
