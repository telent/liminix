{
  description = ''
    Ubiquiti EdgeRouter X (ER-X)
    ****************************

    Hardware summary
    ================

    - MediaTek MT7621AT (880MHz)
    - 256MB NAND Flash
    - 256MB RAM
    - 5x gigE ports (1x PoE in; 1x PoE out @ 24V)

    Limitations
    ===========

    Currently only tftp boots, actual networking currently untested!
  '';

  system = {
    crossSystem = {
      config = "mipsel-unknown-linux-musl";
      gcc = {
        abi = "32";
        # https://openwrt.org/docs/techref/instructionset/mipsel_24kc
        arch = "24kc";
      };
    };
  };

  module = {pkgs, config, lib, lim, ... }:
    let firmware = pkgs.stdenv.mkDerivation {
          name = "wlan-firmware";
          phases = ["installPhase"];
          installPhase = ''
            mkdir $out
            cp ${pkgs.linux-firmware}/lib/firmware/mediatek/{mt7915,mt7615,mt7622}* $out
          '';
        };
    in {
      imports = [
        ../../modules/arch/mipsel.nix
        ../../modules/outputs/tftpboot.nix
      ];
      config = {
        kernel = {
          src = pkgs.pkgsBuildBuild.fetchurl {
            name = "linux.tar.gz";
            url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.137.tar.gz";
            hash = "sha256-PkdzUKZ0IpBiWe/RS70J76JKnBFzRblWcKlaIFNxnHQ=";
          };
          extraPatchPhase = ''
            ${pkgs.openwrt.applyPatches.ramips}
          '';
          config = {
            # Initially taken from openwrt's ./target/linux/ramips/mt7621/config-5.15,
            # then tweaked here and there
            ARCH_32BIT_OFF_T="y";
            ARCH_HIBERNATION_POSSIBLE="y";
            ARCH_KEEP_MEMBLOCK="y";
            ARCH_MMAP_RND_BITS_MAX="15";
            ARCH_MMAP_RND_COMPAT_BITS_MAX="15";
            ARCH_SUSPEND_POSSIBLE="y";
            AT803X_PHY="y";
            BLK_MQ_PCI="y";
            BOARD_SCACHE="y";
            CEVT_R4K="y";
            CLKSRC_MIPS_GIC="y";
            CLK_MT7621="y";
            CLOCKSOURCE_WATCHDOG="y";
            CLONE_BACKWARDS="y";
            CMDLINE_BOOL="y";
            COMMON_CLK="y";
            COMPAT_32BIT_TIME="y";
            CPU_GENERIC_DUMP_TLB="y";
            CPU_HAS_DIEI="y";
            CPU_HAS_PREFETCH="y";
            CPU_HAS_RIXI="y";
            CPU_HAS_SYNC="y";
            CPU_LITTLE_ENDIAN="y";
            CPU_MIPS32="y";
            CPU_MIPS32_R2="y";
            CPU_MIPSR2="y";
            CPU_MIPSR2_IRQ_EI="y";
            CPU_MIPSR2_IRQ_VI="y";
            CPU_NEEDS_NO_SMARTMIPS_OR_MICROMIPS="y";
            CPU_R4K_CACHE_TLB="y";
            CPU_RMAP="y";
            CPU_SUPPORTS_32BIT_KERNEL="y";
            CPU_SUPPORTS_HIGHMEM="y";
            CPU_SUPPORTS_MSA="y";
            CRC16="y";
            CRYPTO_DEFLATE="y";
            CRYPTO_HASH_INFO="y";
            CRYPTO_LIB_BLAKE2S_GENERIC="y";
            CRYPTO_LIB_POLY1305_RSIZE="2";
            CRYPTO_LZO="y";
            CRYPTO_ZSTD="y";
            CSRC_R4K="y";
            DIMLIB="y";
            DMA_NONCOHERENT="y";
            DTB_RT_NONE="y";
            DTC="y";
            EARLY_PRINTK="y";
            FIXED_PHY="y";
            FWNODE_MDIO="y";
            FW_LOADER_PAGED_BUF="y";
            GENERIC_ATOMIC64="y";
            GENERIC_CLOCKEVENTS="y";
            GENERIC_CMOS_UPDATE="y";
            GENERIC_CPU_AUTOPROBE="y";
            GENERIC_FIND_FIRST_BIT="y";
            GENERIC_GETTIMEOFDAY="y";
            GENERIC_IOMAP="y";
            GENERIC_IRQ_CHIP="y";
            GENERIC_IRQ_EFFECTIVE_AFF_MASK="y";
            GENERIC_IRQ_SHOW="y";
            GENERIC_LIB_ASHLDI3="y";
            GENERIC_LIB_ASHRDI3="y";
            GENERIC_LIB_CMPDI2="y";
            GENERIC_LIB_LSHRDI3="y";
            GENERIC_LIB_UCMPDI2="y";
            GENERIC_PCI_IOMAP="y";
            GENERIC_PHY="y";
            GENERIC_PINCONF="y";
            GENERIC_SCHED_CLOCK="y";
            GENERIC_SMP_IDLE_THREAD="y";
            GENERIC_TIME_VSYSCALL="y";
            GLOB="y";
            GPIOLIB_IRQCHIP="y";
            GPIO_CDEV="y";
            GPIO_GENERIC="y";
            GPIO_MT7621="y";
            GRO_CELLS="y";
            HANDLE_DOMAIN_IRQ="y";
            HARDWARE_WATCHPOINTS="y";
            HAS_DMA="y";
            HAS_IOMEM="y";
            HAS_IOPORT_MAP="y";
            I2C="y";
            I2C_ALGOBIT="y";
            I2C_BOARDINFO="y";
            I2C_CHARDEV="y";
            I2C_GPIO="y";
            I2C_MT7621="y";
            ICPLUS_PHY="y";
            IRQCHIP="y";
            IRQ_DOMAIN="y";
            IRQ_DOMAIN_HIERARCHY="y";
            IRQ_FORCED_THREADING="y";
            IRQ_MIPS_CPU="y";
            IRQ_WORK="y";
            LIBFDT="y";
            LOCK_DEBUGGING_SUPPORT="y";
            LZO_COMPRESS="y";
            LZO_DECOMPRESS="y";
            MDIO_BUS="y";
            MDIO_DEVICE="y";
            MDIO_DEVRES="y";
            MEDIATEK_GE_PHY="y";
            MEMFD_CREATE="y";
            MFD_SYSCON="y";
            MIGRATION="y";
            MIKROTIK="y";
            MIKROTIK_RB_SYSFS="y";
            MIPS="y";
            MIPS_ASID_BITS="8";
            MIPS_ASID_SHIFT="0";
            MIPS_CLOCK_VSYSCALL="y";
            MIPS_CM="y";
            MIPS_CPC="y";
            MIPS_CPS="y";
            MIPS_CPU_SCACHE="y";
            MIPS_GIC="y";
            MIPS_L1_CACHE_SHIFT="5";
            MIPS_LD_CAN_LINK_VDSO="y";
            MIPS_MT="y";
            MIPS_MT_FPAFF="y";
            MIPS_MT_SMP="y";
            MIPS_NR_CPU_NR_MAP="4";
            MIPS_PERF_SHARED_TC_COUNTERS="y";
            MIPS_SPRAM="y";
            MODULES_USE_ELF_REL="y";
            MTD_CMDLINE_PARTS="y";
            MTD_NAND_CORE="y";
            MTD_NAND_ECC="y";
            MTD_NAND_ECC_SW_HAMMING="y";
            MTD_NAND_MT7621="y";
            MTD_NAND_MTK_BMT="y";
            MTD_RAW_NAND="y";
            MTD_ROUTERBOOT_PARTS="y";
            MTD_SERCOMM_PARTS="y";
            MTD_SPI_NOR="y";
            MTD_SPLIT_FIT_FW="y";
            MTD_SPLIT_MINOR_FW="y";
            MTD_SPLIT_SEAMA_FW="y";
            MTD_SPLIT_TPLINK_FW="y";
            MTD_SPLIT_TRX_FW="y";
            MTD_SPLIT_UIMAGE_FW="y";
            MTD_UBI="y";
            MTD_UBI_BEB_LIMIT="20";
            MTD_UBI_BLOCK="y";
            MTD_UBI_WL_THRESHOLD="4096";
            MTD_VIRT_CONCAT="y";
            NEED_DMA_MAP_STATE="y";
            NET_DEVLINK="y";
            NET_DSA="y";
            NET_DSA_MT7530="y";
            NET_DSA_MT7530_MDIO="y";
            NET_DSA_TAG_MTK="y";
            NET_FLOW_LIMIT="y";
            NET_MEDIATEK_SOC="y";
            NET_SELFTESTS="y";
            NET_SWITCHDEV="y";
            NET_VENDOR_MEDIATEK="y";
            NO_HZ_COMMON="y";
            NO_HZ_IDLE="y";
            NR_CPUS="4";
            NVMEM="y";
            OF="y";
            OF_ADDRESS="y";
            OF_EARLY_FLATTREE="y";
            OF_FLATTREE="y";
            OF_GPIO="y";
            OF_IRQ="y";
            OF_KOBJ="y";
            OF_MDIO="y";
            PAGE_POOL="y";
            PAGE_POOL_STATS="y";
            PCI="y";
            PCIE_MT7621="y";
            PCI_DISABLE_COMMON_QUIRKS="y";
            PCI_DOMAINS="y";
            PCI_DOMAINS_GENERIC="y";
            PCI_DRIVERS_GENERIC="y";
            PCS_MTK_LYNXI="y";
            PERF_USE_VMALLOC="y";
            PGTABLE_LEVELS="2";
            PHYLIB="y";
            PHYLINK="y";
            PHY_MT7621_PCI="y";
            PINCTRL="y";
            PINCTRL_AW9523="y";
            PINCTRL_MT7621="y";
            PINCTRL_RALINK="y";
            PINCTRL_SX150X="y";
            POWER_RESET="y";
            POWER_RESET_GPIO="y";
            POWER_SUPPLY="y";
            PTP_1588_CLOCK_OPTIONAL="y";
            QUEUED_RWLOCKS="y";
            QUEUED_SPINLOCKS="y";
            RALINK="y";
            RATIONAL="y";
            REGMAP="y";
            REGMAP_I2C="y";
            REGMAP_MMIO="y";
            REGULATOR="y";
            REGULATOR_FIXED_VOLTAGE="y";
            RESET_CONTROLLER="y";
            RFS_ACCEL="y";
            RPS="y";
            RTC_CLASS="y";
            RTC_DRV_BQ32K="y";
            RTC_DRV_PCF8563="y";
            RTC_I2C_AND_SPI="y";
            SCHED_SMT="y";
            SERIAL_8250="y";
            SERIAL_8250_CONSOLE="y";
            SERIAL_8250_NR_UARTS="3";
            SERIAL_8250_RUNTIME_UARTS="3";
            SERIAL_MCTRL_GPIO="y";
            SERIAL_OF_PLATFORM="y";
            SGL_ALLOC="y";
            SMP="y";
            SMP_UP="y";
            SOCK_RX_QUEUE_MAPPING="y";
            SOC_BUS="y";
            SOC_MT7621="y";
            SPI="y";
            SPI_MASTER="y";
            SPI_MEM="y";
            SPI_MT7621="y";
            SRCU="y";
            SWPHY="y";
            SYNC_R4K="y";
            SYSCTL_EXCEPTION_TRACE="y";
            SYS_HAS_CPU_MIPS32_R1="y";
            SYS_HAS_CPU_MIPS32_R2="y";
            SYS_HAS_EARLY_PRINTK="y";
            SYS_SUPPORTS_32BIT_KERNEL="y";
            SYS_SUPPORTS_ARBIT_HZ="y";
            SYS_SUPPORTS_HIGHMEM="y";
            SYS_SUPPORTS_HOTPLUG_CPU="y";
            SYS_SUPPORTS_LITTLE_ENDIAN="y";
            SYS_SUPPORTS_MIPS16="y";
            SYS_SUPPORTS_MIPS_CPS="y";
            SYS_SUPPORTS_MULTITHREADING="y";
            SYS_SUPPORTS_SCHED_SMT="y";
            SYS_SUPPORTS_SMP="y";
            SYS_SUPPORTS_ZBOOT="y";
            TARGET_ISA_REV="2";
            TICK_CPU_ACCOUNTING="y";
            TIMER_OF="y";
            TIMER_PROBE="y";
            TREE_RCU="y";
            TREE_SRCU="y";
            UBIFS_FS="y";
            USB_SUPPORT="y";
            USE_OF="y";
            WEAK_ORDERING="y";
            XPS="y";
            XXHASH="y";
            ZLIB_DEFLATE="y";
            ZLIB_INFLATE="y";
            ZSTD_COMPRESS="y";
            ZSTD_DECOMPRESS="y";
          } // lib.optionalAttrs (config.system.service ? watchdog) {
            RALINK_WDT = "y";  # watchdog
            MT7621_WDT = "y";  # or it might be this one
          };
        };
        boot = {
          commandLine = lib.mkBefore [ "console=ttyS0,57600" ];
          tftp = {
            # Should be a segment of free RAM, where the tftp artifact
            # can be stored before unpacking it to the 'hardware.loadAddress'
            # The 'hardware.loadAddress' is 0x80001000, which suggests the
            # RAM would start at 0x80000000 and (being 256MB) go to
            # to 0x90000000. Let's put it at the 100MB mark at
            # 0x80000000+0x06400000=0x86400000
            loadAddress = lim.parseInt "0x86400000";
            appendDTB = true;
          };
        };
        filesystem =
        let inherit (pkgs.pseudofile) dir symlink;
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
          openwrt = pkgs.openwrt;
          mac80211 =  pkgs.kmodloader.override {
            targets = [
              "mt7915e"
            ];
            inherit (config.system.outputs) kernel;
          };
        in {
          # from OEM bootlog (openwrt wiki):
          # Creating 1 MTD partitions on "raspi":
          # 0x000000000000-0x000000080000 : "SPI_FLASH"
          # Creating 7 MTD partitions on "MT7621-NAND":
          # 0x000000000000-0x00000ff80000 : "ALL"
          # 0x000000000000-0x000000080000 : "Bootloader"
          # 0x000000080000-0x0000000e0000 : "Config"
          # 0x0000000e0000-0x000000140000 : "eeprom"
          # 0x000000140000-0x000000440000 : "Kernel"
          # 0x000000440000-0x000000740000 : "Kernel2"
          # 0x000000740000-0x00000ff00000 : "RootFS"

          # from openwrt bootlog (openwrt wiki):
          # 6 ofpart partitions found on MTD device MT7621-NAND
          # Creating 6 MTD partitions on "MT7621-NAND":
          # 0x000000000000-0x000000080000 : "u-boot"
          # 0x000000080000-0x0000000e0000 : "u-boot-env"
          # 0x0000000e0000-0x000000140000 : "factory"
          # 0x000000140000-0x000000440000 : "kernel1"
          # 0x000000440000-0x000000740000 : "kernel2"
          # 0x000000740000-0x00000ff00000 : "ubi"

          flash = {
            # from the OEM bootlog 'Booting image at at bfd40000 ...'
            # (0x40000 from 0xbfd00000)
            address = lim.parseInt "0xbfd40000";

            # TODO: what should this be for the ER-X??
            # 0x000000040000-0x000000fa0000
            size = lim.parseInt "0xf60000";
            # TODO: find in /proc/mtd on a running system
            eraseBlockSize = 65536;
          };

          defaultOutput = "tftpboot";
          # taken from openwrt factory image:
          # openwrt-23.05.3-ramips-mt7621-ubnt_edgerouter-x-initramfs-kernel.bin: u-boot legacy uImage, MIPS OpenWrt Linux-5.15.150, Linux/MIPS, OS Kernel Image (Not compressed), 5749688 bytes, Fri Mar 22 22:09:42 2024, Load Address: 0X80001000, Entry Point: 0X80001000, Header CRC: 0XE557A849, Data CRC: 0XFD57C463

          loadAddress = lim.parseInt "0x80001000";
          entryPoint = lim.parseInt "0x80001000";

          # TODO: what should this be?
          rootDevice = "/dev/mtdblock3";
          dts = {
            src = "${openwrt.src}/target/linux/ramips/dts/mt7621_ubnt_edgerouter-x.dts";
            includes =  [
              "${openwrt.src}/target/linux/ramips/dts"
              "${config.system.outputs.kernel.modulesupport}/arch/arm64/boot/dts/mediatek/"
            ];
          };

          networkInterfaces =
            let
              inherit (config.system.service.network) link;
            in rec {
              lan1 = link.build { ifname = "lan1"; };
              lan2 = link.build { ifname = "lan2"; };
              lan3 = link.build { ifname = "lan3"; };
              lan4 = link.build { ifname = "lan4"; };
              wan = link.build { ifname = "wan"; };

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

# vim: set ts=2 sw=2 sta et:
