{
  description = ''

== Belkin RT-3200 / Linksys E8450

This device is based on a 64 bit Mediatek MT7622 ARM platform, and has
been powering my (Daniel's) home network since February 2025.

=== Hardware summary

* MediaTek MT7622BV (1350MHz)
* 128MB NAND flash
* 512MB RAM
* b/g/n wireless using MediaTek MT7622BV (MT7615E driver)
* a/n/ac/ax wireless using MediaTek MT7915E

=== Installation

Liminix on this device uses the UBI volume management system to perform
wear leveling on the flash. This is not set up from the factory, so a
one-time step is needed to prepare it before Liminix can be installed.

==== Preparation

To prepare the device for Liminix you first need to use the
https://github.com/dangowrt/owrt-ubi-installer[OpenWrt UBI Installer]
image to rewrite the flash layout. As of Jan 2025 there are two versions
of the installer available: the release version 1.0.2 and the
pre-release 1.1.3 and for Liminix you nee the pre-release. The release
version of the installer creates UBI volumes according to an older
layout that is not compatible with the Linux 6.6.67 kernel used in
Liminix.

You can run the installer in one of two ways: either follow the
instructions to do it through the vendor web interface, or you can drop
to U-Boot and use TFTP

[source,console]
----
MT7622> setenv ipaddr 10.0.0.6
MT7622> setenv serverip 10.0.0.1
MT7622> tftpboot 0x42000000  openwrt-mediatek-mt7622-linksys_e8450-ubi-initramfs-recovery-installer.itb
MT7622> bootm 0x42000000
----

This will write the new flash layout and then boot into a "recovery"
OpenWrt installation.

==== Building/installing Liminix

The default target for this device is `+outputs.ubimage+` which makes a
ubifs image suitable for use with `+ubiupdatevol+`. To write this to the
device we use the OpenWrt recovery system installed in the previous
step. In this configuration the device assigns itself the IP address
192.168.1.1/24 on its LAN ports and expects the connected computer to
have 192.168.1.254

[WARNING]
====
The [.title-ref]#ubi0_7# device in these instructions is correct as of
Dec 2024 (dangowrt/owrt-ubi-installer commit d79e7928). If you are
installing some time later, it is important to check the output from
`+ubinfo -a+` and make sure you are updating the "liminix" volume and
not some other one which had been introduced since I wrote this.
====

[source,console]
----
$ nix-build -I liminix-config=./my-configuration.nix  --arg device "import ./devices/belkin-rt3200" -A outputs.default
$ cat result/rootfs | ssh root@192.168.1.1 "cat > /tmp/rootfs"
$ ssh root@192.168.1.1
root@OpenWrt:~# ubimkvol /dev/ubi0 --name=liminix --maxavsize
root@OpenWrt:~# ubinfo -a
[...]
Volume ID:   7 (on ubi0)
Type:        dynamic
Alignment:   1
Size:        851 LEBs (108056576 bytes, 103.0 MiB)
State:       OK
Name:        liminix
Character device major/minor: 250:8
root@OpenWrt:~# ubiupdatevol /dev/ubi0_7 /tmp/rootfs
----

To make the new system bootable we also need to change some U-Boot
variables. `+boot_production+` needs to mount the filesystem and boot
the FIT image found there, and `+bootcmd+` needs to be told not to boot
the rescue image if there are records in pstore, because that interferes
with `+config.log.persistent+`

[source,console]
----
root@OpenWrt:~# fw_setenv orig_boot_production $(fw_printenv -n boot_production)
root@OpenWrt:~# fw_setenv orig_bootcmd $(fw_printenv -n bootcmd)
root@OpenWrt:~# fw_setenv boot_production 'led $bootled_pwr on ; ubifsmount ubi0:liminix && ubifsload ''${loadaddr} boot/fit && bootm ''${loadaddr}'
root@OpenWrt:~# fw_setenv bootcmd 'run boot_ubi'
----

For subsequent Liminix reinstalls, just run the `+ubiupdatevol+` command
again. You don't need to repeat the "Preparation" step and in fact
should seek to avoid it if possible, as it will reset the erase counters
used for write levelling. Using UBI-aware tools is therefore preferred
over any kind of "factory" wipe which will reset them.

  '';

  system = {
    crossSystem = {
      config = "aarch64-unknown-linux-musl";
    };
  };

  module =
    {
      pkgs,
      config,
      lib,
      lim,
      ...
    }:
    let
      inherit (lib) mkIf;
      firmware = pkgs.stdenv.mkDerivation {
        name = "wlan-firmware";
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir $out
          cp ${pkgs.linux-firmware}/lib/firmware/mediatek/{mt7915,mt7615,mt7622}* $out
        '';
      };
      openwrt = pkgs.openwrt_24_10;
    in
    {
      imports = [
        ../../modules/arch/aarch64.nix
        ../../modules/outputs/tftpboot.nix
        ../../modules/outputs/ubifs.nix
      ];
      config = {
        kernel = {
          extraPatchPhase = ''
            ${openwrt.applyPatches.mediatek}
          '';
          src = openwrt.kernelSrc;
          version = openwrt.kernelVersion;
          config = {
            PCI = "y";
            ARCH_MEDIATEK = "y";
            # ARM_MEDIATEK_CPUFREQ = "y";

            # needed for "Cannot find regmap for /infracfg@10000000"
            MFD_SYSCON = "y";
            MTK_INFRACFG = "y";

            MTK_PMIC_WRAP = "y";
            DMADEVICES = "y";
            MTK_HSDMA = "y";
            MTK_SCPSYS = "y";
            MTK_SCPSYS_PM_DOMAINS = "y";
            # MTK_THERMAL="y";
            MTK_TIMER = "y";

            COMMON_CLK_MT7622 = "y";
            COMMON_CLK_MT7622_ETHSYS = "y";
            COMMON_CLK_MT7622_HIFSYS = "y";
            COMMON_CLK_MT7622_AUDSYS = "y";
            PM_CLK = "y";

            REGMAP_MMIO = "y";
            CLKSRC_MMIO = "y";
            REGMAP = "y";

            MEDIATEK_GE_PHY = "y";
            # MEDIATEK_MT6577_AUXADC = "y";
            NET_MEDIATEK_SOC = "y";
            NET_MEDIATEK_SOC_WED = "y";
            NET_MEDIATEK_STAR_EMAC = "y"; # this enables REGMAP_MMIO
            NET_VENDOR_MEDIATEK = "y";
            PCIE_MEDIATEK = "y";

            BLOCK = "y"; # move this to base option

            SPI_MASTER = "y";
            SPI = "y";
            SPI_MEM = "y";
            SPI_MTK_NOR = "y";
            SPI_MTK_SNFI = "y";

            MTD = "y";
            MTD_BLOCK = "y";
            MTD_RAW_NAND = "y";
            MTD_NAND_MTK = "y";
            MTD_NAND_MTK_BMT = "y"; # Bad-block Management Table
            MTD_NAND_ECC_MEDIATEK = "y";
            MTD_NAND_ECC_SW_HAMMING = "y";
            MTD_SPI_NAND = "y";
            MTD_OF_PARTS = "y";
            MTD_NAND_CORE = "y";
            MTD_SPI_NOR = "y";
            MTD_SPLIT_FIRMWARE = "y";
            MTD_SPLIT_FIT_FW = "y";

            MTD_UBI_NVMEM = "y";
            NVMEM_MTK_EFUSE = "y";
            NVMEM_BLOCK = "y";
            NVMEM_LAYOUT_ADTRAN = "y";

            MMC = "y";
            MMC_BLOCK = "y";
            MMC_CQHCI = "y";
            MMC_MTK = "y";

            # Distributed Switch Architecture is needed
            # to make the ethernet ports visible
            NET_DSA = "y";
            NET_DSA_MT7530 = "y";
            NET_DSA_TAG_MTK = "y";
            NET_DSA_MT7530_MDIO = "y";

            SERIAL_8250 = "y";
            SERIAL_8250_CONSOLE = "y";
            SERIAL_8250_MT6577 = "y";
            # SERIAL_8250_NR_UARTS="3";
            # SERIAL_8250_RUNTIME_UARTS="3";
            SERIAL_OF_PLATFORM = "y";

            # Must enble hardware watchdog drivers. Else the device reboots after several seconds
            WATCHDOG = "y";
            MEDIATEK_WATCHDOG = "y";
          };
          conditionalConfig = {
            WLAN = {
              MT7615E = "m";
              MT7622_WMAC = "y";
              MT7915E = "m";
            };
          };
        };
        boot = {
          commandLine = [ "console=ttyS0,115200" ];
          tftp.loadAddress = lim.parseInt "0x48000000";
          imageFormat = "fit";
          loader.fit.enable = lib.mkDefault true; # override this if you are building tftpboot
        };
        rootfsType = lib.mkDefault "ubifs"; # override this if you are building tftpboot
        filesystem =
          let
            inherit (pkgs.pseudofile) dir symlink;
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
            mac80211 = pkgs.kmodloader.override {
              targets = [
                "mt7615e"
                "mt7915e"
              ];
              inherit (config.system.outputs) kernel;
            };
          in
          {
            ubi = {
              minIOSize = "2048";
              logicalEraseBlockSize = "126976";
              physicalEraseBlockSize = "131072";
              maxLEBcount = "1024"; # guessing
            };

            defaultOutput = "ubimage";
            # the kernel expects this to be on a 2MB boundary. U-Boot
            # (I don't know why) has a default of 0x41080000, which isn't.
            # We put it at the 32MB mark so that tftpboot can put its rootfs
            # image and DTB underneath, but maybe this is a terrible waste of
            # RAM unless the kernel is able to reuse it later. Oh well
            loadAddress = lim.parseInt "0x42000000";
            entryPoint = lim.parseInt "0x42000000";
            rootDevice = "ubi0:liminix";
            dts = {
              src = "${openwrt.src}/target/linux/mediatek/dts/mt7622-linksys-e8450-ubi.dts";
              includePaths = [
                "${openwrt.src}/target/linux/mediatek/dts"
                "${config.system.outputs.kernel.modulesupport}/arch/arm64/boot/dts/mediatek/"
              ];
              includes = mkIf config.logging.persistent.enable [
                ./pstore-pmsg.dtsi
              ];
            };

            # - 0x000000000000-0x000008000000 : "spi-nand0"
            #         - 0x000000000000-0x000000080000 : "bl2"
            #         - 0x000000080000-0x0000001c0000 : "fip"
            #         - 0x0000001c0000-0x0000002c0000 : "factory"
            #         - 0x0000002c0000-0x000000300000 : "reserved"
            #         - 0x000000300000-0x000008000000 : "ubi"

            networkInterfaces =
              let
                inherit (config.system.service.network) link;
              in
              rec {
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
    };
}
