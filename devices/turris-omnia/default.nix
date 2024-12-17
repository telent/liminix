{
  description = ''
    Turris Omnia
    ************

    This is a 32 bit ARMv7 MVEBU device, which is usually shipped with
    TurrisOS, an OpenWrt-based system. Rather than reformatting the
    builtin storage, we install Liminix on to the existing btrfs
    filesystem so that the vendor snapshot/recovery system continues
    to work (and provides you an easy rollback if you decide you don't
    like Liminix after all).

    The install process has two stages, and is intended that you
    should not need to open the device and add a serial console
    (although it may be handy for visibility, and in case anything
    goes wrong). First we build a minimal installation/recovery
    system, then we reboot into that recovery image to prepare the
    device for the full target install.

    Installation using a USB stick
    ==============================

    First, build the image for the USB stick. Review
    :file:`examples/recovery.nix` in order to change the default
    root password (which is ``secret``) and/or the SSH keys, then
    build it with

    .. code-block:: console

        $ nix-build -I liminix-config=./examples/recovery.nix \
          --arg device "import ./devices/turris-omnia" \
          -A outputs.mbrimage -o mbrimage
        $ file -L mbrimage
        mbrimage: DOS/MBR boot sector; partition 1 : ID=0x83, active, start-CHS (0x0,0,5), end-CHS (0x6,130,26), startsector 4, 104602 sectors

    Next, copy the image from your build machine to a USB storage
    medium using :command:`dd` or your other most favoured file copying
    tool, which might be a comand something like this:

    .. code-block:: console

        $ dd if=mbrimage of=/dev/path/to/the/usb/stick \
          bs=1M conv=fdatasync status=progress

    The Omnia's default boot order only checks USB after it has failed
    to boot from eMMC, which is not ideal for our purpose.  Unless you
    have a serial cable, the easiest way to change this is by booting
    to TurrisOS and logging in with ssh:

    .. code-block:: console

        root@turris:/# fw_printenv boot_targets
        boot_targets=mmc0 nvme0 scsi0 usb0 pxe dhcp
        root@turris:/# fw_setenv boot_targets usb0 mmc0
        root@turris:/# fw_printenv boot_targets
        boot_targets=usb0 mmc0
        root@turris:/# reboot -f

    It should now boot into the recovery image. It expects a network
    cable to be plugged into LAN2 with something on the other end of
    it that serves DHCP requests.  Check your DHCP server logs for a
    request from a ``liminix-recovery`` host and figure out what IP
    address was assigned.

    .. code-block:: console

        $ ssh liminix-recovery.lan

    You should get a "Busybox" banner and a root prompt. Now you can
    start preparing the device to install Liminix on it. First we'll
    mount the root filesystem and take a snapshot:

    .. code-block:: console

        # mkdir /dest && mount /dev/mmcblk0p1 /dest
        # schnapps -d /dest create "pre liminix"
        # schnapps -d /dest list
        ERROR: not a valid btrfs filesystem: /
            # | Type      | Size        | Date                      | Description
        ------+-----------+-------------+---------------------------+------------------------------------
            1 | single    |    16.00KiB | 1970-01-01 00:11:49 +0000 | pre liminix

    (``not a valid btrfs filesystem: /`` is not a real error)

    then we can remove all the files

    .. code-block:: console

        # rm -r /dest/@/*

    and then it's ready to install the real Liminix system onto. On
    your build system, create the Liminix configuration you wish to
    install: here we'll use the ``rotuer`` example.

    .. code-block:: console

        build$ nix-build -I liminix-config=./examples/rotuer.nix \
          --arg device "import ./devices/turris-omnia" \
          -A outputs.systemConfiguration

    and then use :command:`min-copy-closure` to copy it to the device.

    .. code-block:: console

        build$ nix-shell --run \
          "min-copy-closure -r /dest/@  root@liminix-recovery.lan result"

    and activate it

    .. code-block:: console

        build$ ssh root@liminix-recovery.lan \
          "/dest/@/$(readlink result)/bin/install /dest/@"

    The final steps are performed directly on the device again: add
    a symlink so U-Boot can find :file:`/boot`, then restore the
    default boot order and reboot into the new configuration.

    .. code-block:: console

        # cd /dest && ln -s @/boot .
        # fw_setenv boot_targets "mmc0 nvme0 scsi0 usb0 pxe dhcp"
        # cd / ; umount /dest
        # reboot


    Installation using a TFTP server and serial console
    ===================================================

    If you have a :ref:`serial` console connection and a TFTP server,
    and would rather use them than fiddling with USB sticks, the
    :file:`examples/recovery.nix` configuration also works
    using the ``tftpboot`` output. So you can do

    .. code-block:: console

        build$ nix-build -I liminix-config=./examples/recovery.nix \
          --arg device "import ./devices/turris-omnia" \
          -A outputs.tftpboot

    and then paste the generated :file:`result/boot.scr` into
    U-Boot, and you will end up with the same system as you would
    have had after booting from USB. If you don't have a serial
    console connection you could probably even get clever with
    elaborate use of :command:`fw_setenv`, but that is left as
    an exercise for the reader.

  '';

  system = {
    crossSystem = {
      config = "armv7l-unknown-linux-musleabihf";
    };
  };

  module = {pkgs, config, lib, lim, ... }:
    let
      inherit (pkgs.liminix.services) oneshot;
      inherit (pkgs) liminix;
      mtd_by_name_links = pkgs.liminix.services.oneshot rec  {
        name = "mtd_by_name_links";
        up = ''
          mkdir -p /dev/mtd/by-name
          cd /dev/mtd/by-name
          for i in /sys/class/mtd/mtd*[0-9]; do
            ln -s ../../$(basename $i) $(cat $i/name)
          done
        '';
      };
    in {
      imports = [
        ../../modules/arch/arm.nix
        ../../modules/outputs/tftpboot.nix
        ../../modules/outputs/mbrimage.nix
        ../../modules/outputs/extlinux.nix
      ];

      config = {
        services.mtd-name-links = mtd_by_name_links;
        kernel = {
          src = pkgs.pkgsBuildBuild.fetchurl {
            name = "linux.tar.gz";
            url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.7.4.tar.gz";
            hash = "sha256-wIrmL0BS63nRwWfm4nw+dRNVPUzGh9M4X7LaHzAn5tU=";
          };
          version = "6.7.4";
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

            RTC_CLASS = "y";
            RTC_DRV_ARMADA38X = "y"; # this may be useful anyway?

            EXPERT = "y";
            ALLOW_DEV_COREDUMP = "n";


            # dts has a compatible for this but dmesg is not
            # showing it
            EEPROM_AT24 = "y"; # atmel,24c64

            I2C = "y";
            I2C_MUX = "y";
            I2C_MUX_PCA954x = "y";

            MACH_ARMADA_38X = "y";
            SMP = "y";
	          # this is disabled for the moment because it relies on a
            # GCC plugin that requires gmp.h to build, and I can't see
            # right now how to confgure it to find gmp
            STACKPROTECTOR_PER_TASK = "n";
            NR_CPUS = "4";
            VFP = "y";
            NEON= "y";

            # WARNING: unmet direct dependencies detected for ARCH_WANT_LIBATA_LEDS
            ATA = "y";

            PSTORE = "y";
            PSTORE_RAM = "y";
            PSTORE_CONSOLE = "y";
#            PSTORE_DEFLATE_COMPRESS = "n";

            BLOCK = "y";
            MMC="y";
            PWRSEQ_EMMC="y";        # ???
            PWRSEQ_SIMPLE="y";      # ???
            MMC_BLOCK="y";

            MMC_SDHCI= "y";
            MMC_SDHCI_PLTFM= "y";
            MMC_SDHCI_PXAV3= "y";
            MMC_MVSDIO= "y";

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
            SRAM = "y"; # mmio-sram is "compatible" for bm_bppi reqd by BM
            PHY_MVEBU_A38X_COMPHY = "y"; # for eth2
            MARVELL_PHY = "y";

            MVPP2 = "y";
            MV_XOR = "y";

            # there is NOR flash on this device, which is used for U-Boot
            # and the rescue system (which we don't interfere with) but
            # also for the U-Boot environment variables (which we might
            # need to meddle with)
            MTD_SPI_NOR = "y";
            SPI = "y";
            SPI_MASTER = "y";
            SPI_ORION = "y";

            NET_DSA = "y";
            NET_DSA_MV88E6XXX = "y"; # depends on PTP_1588_CLOCK_OPTIONAL
          };
          conditionalConfig = {
            USB = {
              USB_XHCI_MVEBU = "y";
              USB_XHCI_HCD = "y";
            };
            WLAN = {
              WLAN_VENDOR_ATH = "y";
              ATH_COMMON = "m";
              ATH9K = "m";
              ATH9K_PCI = "y";
              ATH10K = "m";
              ATH10K_PCI = "m";
              ATH10K_DEBUG = "y";
            };
          };
        };
        boot = {
          commandLine = [
            "console=ttyS0,115200"
            "pcie_aspm=off" # ath9k pci incompatible with PCIe ASPM
          ];
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
            etc = dir {
              "fw_env.config" =
                let f = pkgs.writeText "fw_env.config" ''
                  /dev/mtd/by-name/u-boot-env 0x0 0x10000 0x10000
                '';
                in symlink f;
            };
          };

        boot.tftp = {
          loadAddress = lim.parseInt "0x1700000";
          kernelFormat = "zimage";
          compressRoot = true;
        };

        hardware = let
          mac80211 =  pkgs.kmodloader.override {
            inherit (config.system.outputs) kernel;
            targets = ["ath9k" "ath10k_pci"];
          };
        in {
          defaultOutput = "mtdimage";
          loadAddress = lim.parseInt "0x00800000"; # "0x00008000";
          entryPoint = lim.parseInt "0x00800000"; # "0x00008000";
          rootDevice = "/dev/mmcblk0p1";

          dts = {
            src = "${config.system.outputs.kernel.modulesupport}/arch/arm/boot/dts/marvell/armada-385-turris-omnia.dts";
            includePaths =  [
              "${config.system.outputs.kernel.modulesupport}/arch/arm/boot/dts/marvell/"
            ];
          };
          flash.eraseBlockSize = 65536; # only used for tftpboot
          networkInterfaces =
            let
              inherit (config.system.service.network) link;
            in rec {
              en70000 = link.build {
                # in armada-38x.dtsi this is eth0.
                # It's connected to port 5 of the 88E6176 switch
                devpath = "/devices/platform/soc/soc:internal-regs/f1070000.ethernet";
                # name is unambiguous but not very semantic
                ifname = "en70000";
              };
              en30000 = link.build {
                # in armada-38x.dtsi this is eth1
                # It's connected to port 6 of the 88E6176 switch
                devpath = "/devices/platform/soc/soc:internal-regs/f1030000.ethernet";
                # name is unambiguous but not very semantic
                ifname = "en30000";
              };
              # the default (from the dts? I'm guessing) behavour for
              # lan ports on the switch is to attach them to
              # en30000. It should be possible to do something better,
              # per
              # https://www.kernel.org/doc/html/latest/networking/dsa/configuration.html#affinity-of-user-ports-to-cpu-ports
              # but apparently OpenWrt doesn't either so maybe it's more
              # complicated than it looks.

              wan = link.build {
                # in armada-38x.dtsi this is eth2. It may be connected to
                # an ethernet phy or to the SFP cage, depending on a gpio
                devpath = "/devices/platform/soc/soc:internal-regs/f1034000.ethernet";
                ifname = "wan";
              };

              lan0 = link.build { ifname = "lan0"; };
              lan1 = link.build { ifname = "lan1"; };
              lan2 = link.build { ifname = "lan2"; };
              lan3 = link.build { ifname = "lan3"; };
              lan4 = link.build { ifname = "lan4"; };
              lan5 = link.build { ifname = "lan5"; };
              lan = lan0; # maybe we should build a bridge?

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
    };
}
