{
  system.crossSystem.config = "aarch64-unknown-linux-musl";

  description = builtins.readFile ./hardware.adoc;

  module =
    {
      pkgs,
      config,
      lim,
      ...
    }:
    let
      openwrt = pkgs.openwrt_25_12;
      inherit (pkgs.pseudofile) dir symlink;
      firmware = pkgs.runCommand "flint2-radio-firmware" { } ''
        mkdir -p $out
        # OpenWrt package/kernel/mt76/Makefile: mt7986-firmware
        # OpenWrt package/firmware/linux-firmware/mediatek.mk: mt7986-wo-firmware
        cd ${pkgs.linux-firmware}/lib/firmware/mediatek
        cp -L mt7986_{wa,wm,wm_mt7975,rom_patch,rom_patch_mt7975,wo_0,wo_1}.bin "$out/"
      '';
    in
    {
      imports = [
        ../../modules/arch/aarch64.nix
        ../../modules/outputs/tftpboot.nix
        ./factory.nix
      ];
      kernel = {
        src = openwrt.kernelSrc;
        version = openwrt.kernelVersion;
        extraPatchPhase = openwrt.applyPatches.mediatek;
        config = {
          NET = "y"; # unlock NET_XGRESS
          SERIAL_8250 = "y"; # unlock SERIAL_8250_FSL
          SERIAL_8250_CONSOLE = "y"; # to get the serial console
          WATCHDOG = "y"; # unlock WATCHDOG_CORE
          NEW_LEDS = "y"; # unlock LEDS_PWM
          LEDS_CLASS = "y"; # unlock LEDS_PWM
          LEDS_TRIGGERS = "y"; # unlock LEDS_TRIGGER_PATTERN
          DEFERRED_STRUCT_PAGE_INIT = "y"; # trigger PADATA
          # Taken from openwrt's ./target/linux/mediatek/filogic/config-6.6
          "64BIT" = "y";
          AIROHA_EN8801SC_PHY = "y";
          ARCH_BINFMT_ELF_EXTRA_PHDRS = "y";
          ARCH_CORRECT_STACKTRACE_ON_KRETPROBE = "y";
          ARCH_DEFAULT_KEXEC_IMAGE_VERIFY_SIG = "y";
          ARCH_DMA_ADDR_T_64BIT = "y";
          ARCH_KEEP_MEMBLOCK = "y";
          ARCH_MEDIATEK = "y";
          ARCH_MHP_MEMMAP_ON_MEMORY_ENABLE = "y";
          ARCH_PROC_KCORE_TEXT = "y";
          ARCH_SPARSEMEM_ENABLE = "y";
          ARCH_STACKWALK = "y";
          ARCH_SUSPEND_POSSIBLE = "y";
          ARCH_WANTS_NO_INSTR = "y";
          ARM64 = "y";
          ARM64_ERRATUM_843419 = "y";
          ARM64_LD_HAS_FIX_ERRATUM_843419 = "y";
          ARM64_TAGGED_ADDR_ABI = "y";
          ARM_AMBA = "y";
          ARM_ARCH_TIMER = "y";
          ARM_ARCH_TIMER_EVTSTREAM = "y";
          ARM_GIC = "y";
          ARM_GIC_V2M = "y";
          ARM_GIC_V3 = "y";
          ARM_GIC_V3_ITS = "y";
          ARM_MEDIATEK_CCI_DEVFREQ = "y";
          ARM_MEDIATEK_CPUFREQ = "y";
          ARM_PMU = "y";
          ARM_PMUV3 = "y";
          ARM_PSCI_FW = "y";
          ATA = "y";
          AUDIT_ARCH_COMPAT_GENERIC = "y";
          BLK_DEV_LOOP = "y";
          BLK_DEV_SD = "y";
          BLK_MQ_PCI = "y";
          BLK_PM = "y";
          BLOCK_NOTIFIERS = "y";
          BSD_PROCESS_ACCT = "y";
          BSD_PROCESS_ACCT_V3 = "y";
          BUFFER_HEAD = "y";
          BUILTIN_RETURN_ADDRESS_STRIPS_PAC = "y";
          CC_HAVE_SHADOW_CALL_STACK = "y";
          CC_HAVE_STACKPROTECTOR_SYSREG = "y";
          #CC_IMPLICIT_FALLTHROUGH="-Wimplicit-fallthrough=5";
          CLKSRC_MMIO = "y";
          CLONE_BACKWARDS = "y";
          CMDLINE_OVERRIDE = "y";
          COMMON_CLK = "y";
          COMMON_CLK_MEDIATEK = "y";
          COMMON_CLK_MT7981 = "y";
          COMMON_CLK_MT7981_ETHSYS = "y";
          COMMON_CLK_MT7986 = "y";
          COMMON_CLK_MT7986_ETHSYS = "y";
          COMMON_CLK_MT7988 = "y";
          COMPACT_UNEVICTABLE_DEFAULT = "1";
          CONFIGFS_FS = "y";
          CONSOLE_LOGLEVEL_DEFAULT = "15";
          CONTEXT_TRACKING = "y";
          CONTEXT_TRACKING_IDLE = "y";
          CPU_FREQ = "y";
          CPU_FREQ_DEFAULT_GOV_USERSPACE = "y";
          CPU_FREQ_GOV_ATTR_SET = "y";
          CPU_FREQ_GOV_COMMON = "y";
          CPU_FREQ_GOV_CONSERVATIVE = "y";
          CPU_FREQ_GOV_ONDEMAND = "y";
          CPU_FREQ_GOV_PERFORMANCE = "y";
          CPU_FREQ_GOV_POWERSAVE = "y";
          CPU_FREQ_GOV_SCHEDUTIL = "y";
          CPU_FREQ_GOV_USERSPACE = "y";
          CPU_FREQ_STAT = "y";
          CPU_LITTLE_ENDIAN = "y";
          CPU_RMAP = "y";
          CPU_THERMAL = "y";
          CRC16 = "y";
          CRC_CCITT = "y";
          CRYPTO_AES_ARM64 = "y";
          CRYPTO_AES_ARM64_CE = "y";
          CRYPTO_AES_ARM64_CE_BLK = "y";
          CRYPTO_AES_ARM64_CE_CCM = "y";
          CRYPTO_CMAC = "y";
          CRYPTO_CRC32 = "y";
          CRYPTO_CRC32C = "y";
          CRYPTO_CRYPTD = "y";
          CRYPTO_DEFLATE = "y";
          CRYPTO_DRBG = "y";
          CRYPTO_DRBG_HMAC = "y";
          CRYPTO_DRBG_MENU = "y";
          CRYPTO_ECB = "y";
          CRYPTO_ECC = "y";
          CRYPTO_ECDH = "y";
          CRYPTO_GHASH_ARM64_CE = "y";
          CRYPTO_HASH_INFO = "y";
          CRYPTO_HMAC = "y";
          CRYPTO_JITTERENTROPY = "y";
          CRYPTO_LIB_BLAKE2S_GENERIC = "y";
          CRYPTO_LIB_GF128MUL = "y";
          CRYPTO_LIB_SHA1 = "y";
          CRYPTO_LIB_SHA256 = "y";
          CRYPTO_LIB_UTILS = "y";
          CRYPTO_LZO = "y";
          CRYPTO_RNG = "y";
          CRYPTO_RNG2 = "y";
          CRYPTO_RNG_DEFAULT = "y";
          CRYPTO_SHA256 = "y";
          CRYPTO_SHA256_ARM64 = "y";
          CRYPTO_SHA2_ARM64_CE = "y";
          CRYPTO_SHA3 = "y";
          CRYPTO_SHA512 = "y";
          CRYPTO_SM4 = "y";
          CRYPTO_SM4_ARM64_CE_BLK = "y";
          CRYPTO_SM4_ARM64_CE_CCM = "y";
          CRYPTO_SM4_ARM64_CE_GCM = "y";
          CRYPTO_ZSTD = "y";
          DCACHE_WORD_ACCESS = "y";
          #DEBUG_INFO="y";
          DEBUG_MISC = "y";
          DEVFREQ_GOV_PASSIVE = "y";
          DIMLIB = "y";
          DMADEVICES = "y";
          DMATEST = "y";
          DMA_BOUNCE_UNALIGNED_KMALLOC = "y";
          DMA_DIRECT_REMAP = "y";
          DMA_ENGINE = "y";
          DMA_ENGINE_RAID = "y";
          DMA_OF = "y";
          DMA_VIRTUAL_CHANNELS = "y";
          DTC = "y";
          EDAC_SUPPORT = "y";
          EINT_MTK = "y";
          EXCLUSIVE_SYSTEM_RAM = "y";
          EXT4_FS = "y";
          F2FS_FS = "y";
          FIXED_PHY = "y";
          FIX_EARLYCON_MEM = "y";
          FRAME_POINTER = "y";
          FS_IOMAP = "y";
          FS_MBCACHE = "y";
          FUNCTION_ALIGNMENT = "4";
          FUNCTION_ALIGNMENT_4B = "y";
          FWNODE_MDIO = "y";
          FW_LOADER_PAGED_BUF = "y";
          #FW_LOADER_SYSFS="y";
          #GCC11_NO_ARRAY_BOUNDS="y";
          #GCC_ASM_GOTO_OUTPUT_WORKAROUND="y";
          GENERIC_ALLOCATOR = "y";
          GENERIC_ARCH_TOPOLOGY = "y";
          GENERIC_BUG = "y";
          GENERIC_BUG_RELATIVE_POINTERS = "y";
          GENERIC_CLOCKEVENTS = "y";
          GENERIC_CLOCKEVENTS_BROADCAST = "y";
          GENERIC_CPU_AUTOPROBE = "y";
          GENERIC_CPU_VULNERABILITIES = "y";
          GENERIC_CSUM = "y";
          GENERIC_EARLY_IOREMAP = "y";
          GENERIC_GETTIMEOFDAY = "y";
          GENERIC_IDLE_POLL_SETUP = "y";
          GENERIC_IOREMAP = "y";
          GENERIC_IRQ_EFFECTIVE_AFF_MASK = "y";
          GENERIC_IRQ_SHOW = "y";
          GENERIC_IRQ_SHOW_LEVEL = "y";
          GENERIC_LIB_DEVMEM_IS_ALLOWED = "y";
          GENERIC_MSI_IRQ = "y";
          GENERIC_PCI_IOMAP = "y";
          GENERIC_PHY = "y";
          GENERIC_PINCONF = "y";
          GENERIC_PINCTRL_GROUPS = "y";
          GENERIC_PINMUX_FUNCTIONS = "y";
          GENERIC_SCHED_CLOCK = "y";
          GENERIC_SMP_IDLE_THREAD = "y";
          GENERIC_STRNCPY_FROM_USER = "y";
          GENERIC_STRNLEN_USER = "y";
          GENERIC_TIME_VSYSCALL = "y";
          GLOB = "y";
          GPIO_CDEV = "y";
          GPIO_WATCHDOG = "y";
          GPIO_WATCHDOG_ARCH_INITCALL = "y";
          GRO_CELLS = "y";
          HARDIRQS_SW_RESEND = "y";
          HAS_DMA = "y";
          HAS_IOMEM = "y";
          HAS_IOPORT = "y";
          HAS_IOPORT_MAP = "y";
          HWMON = "y";
          HW_RANDOM = "y";
          HW_RANDOM_MTK = "y";
          I2C = "y";
          I2C_BOARDINFO = "y";
          I2C_CHARDEV = "y";
          I2C_MT65XX = "y";
          ICPLUS_PHY = "y";
          ILLEGAL_POINTER_VALUE = "0xdead000000000000";
          #INITRAMFS_SOURCE="""";
          IRQCHIP = "y";
          IRQ_DOMAIN = "y";
          IRQ_DOMAIN_HIERARCHY = "y";
          IRQ_FORCED_THREADING = "y";
          IRQ_TIME_ACCOUNTING = "y";
          IRQ_WORK = "y";
          JBD2 = "y";
          JUMP_LABEL = "y";
          LEDS_PWM = "y";
          LEDS_SMARTRG_LED = "y";
          LEDS_TRIGGER_PATTERN = "y";
          LIBFDT = "y";
          LOCK_DEBUGGING_SUPPORT = "y";
          LOCK_SPIN_ON_OWNER = "y";
          LZO_COMPRESS = "y";
          LZO_DECOMPRESS = "y";
          MAGIC_SYSRQ = "y";
          MAXLINEAR_GPHY = "y";
          MDIO_BUS = "y";
          MDIO_DEVICE = "y";
          MDIO_DEVRES = "y";
          MEDIATEK_2P5GE_PHY = "y";
          MEDIATEK_GE_PHY = "y";
          MEDIATEK_GE_SOC_PHY = "y";
          MEDIATEK_WATCHDOG = "y";
          MESSAGE_LOGLEVEL_DEFAULT = "7";
          MFD_SYSCON = "y";
          MIGRATION = "y";
          MMC = "y";
          MMC_BLOCK = "y";
          MMC_CQHCI = "y";
          MMC_MTK = "y";
          MMU_LAZY_TLB_REFCOUNT = "y";
          MODULES_TREE_LOOKUP = "y";
          MODULES_USE_ELF_RELA = "y";
          MTD_NAND_CORE = "y";
          MTD_NAND_ECC = "y";
          MTD_NAND_ECC_MEDIATEK = "y";
          MTD_NAND_ECC_SW_HAMMING = "y";
          MTD_NAND_MTK = "y";
          MTD_NAND_MTK_BMT = "y";
          MTD_PARSER_TRX = "y";
          MTD_RAW_NAND = "y";
          MTD_SPI_NAND = "y";
          MTD_SPI_NOR = "y";
          MTD_SPLIT_FIRMWARE = "y";
          MTD_SPLIT_FIT_FW = "y";
          MTD_SPLIT_MSTC_BOOT = "y";
          MTD_UBI = "y";
          MTD_UBI_BEB_LIMIT = "20";
          MTD_UBI_BLOCK = "y";
          MTD_UBI_FASTMAP = "y";
          MTD_UBI_NVMEM = "y";
          MTD_UBI_WL_THRESHOLD = "4096";
          MTK_CPUX_TIMER = "y";
          MTK_HSDMA = "y";
          MTK_INFRACFG = "y";
          MTK_LVTS_THERMAL = "y";
          MTK_LVTS_THERMAL_DEBUGFS = "y";
          MTK_PMIC_WRAP = "y";
          MTK_REGULATOR_COUPLER = "y";
          MTK_SCPSYS = "y";
          MTK_SCPSYS_PM_DOMAINS = "y";
          MTK_SOC_THERMAL = "y";
          MTK_THERMAL = "y";
          MTK_TIMER = "y";
          MUTEX_SPIN_ON_OWNER = "y";
          NEED_DMA_MAP_STATE = "y";
          NEED_SG_DMA_LENGTH = "y";
          NET_DEVLINK = "y";
          NET_DSA = "y";
          NET_DSA_MT7530 = "y";
          NET_DSA_MT7530_MDIO = "y";
          NET_DSA_MT7530_MMIO = "y";
          NET_DSA_TAG_MTK = "y";
          #NET_EGRESS="y";
          NET_FLOW_LIMIT = "y";
          #NET_INGRESS="y";
          NET_MEDIATEK_SOC = "y";
          NET_MEDIATEK_SOC_WED = "y";
          NET_SELFTESTS = "y";
          NET_SWITCHDEV = "y";
          NET_VENDOR_MEDIATEK = "y";
          #NET_XGRESS="y";
          NLS = "y";
          NO_HZ_COMMON = "y";
          NO_HZ_IDLE = "y";
          NR_CPUS = "4";
          NVMEM = "y";
          NVMEM_BLOCK = "y";
          NVMEM_LAYOUTS = "y";
          NVMEM_LAYOUT_ADTRAN = "y";
          NVMEM_MTK_EFUSE = "y";
          NVMEM_SYSFS = "y";
          OF = "y";
          OF_ADDRESS = "y";
          OF_DYNAMIC = "y";
          OF_EARLY_FLATTREE = "y";
          OF_FLATTREE = "y";
          OF_GPIO = "y";
          OF_IRQ = "y";
          OF_KOBJ = "y";
          OF_MDIO = "y";
          OF_OVERLAY = "y";
          OF_RESOLVE = "y";
          PADATA = "y";
          PAGE_POOL = "y";
          PAGE_POOL_STATS = "y";
          #PAHOLE_HAS_LANG_EXCLUDE="y";
          PARTITION_PERCPU = "y";
          PCI = "y";
          PCIEAER = "y";
          PCIEASPM = "y";
          PCIEASPM_PERFORMANCE = "y";
          PCIEPORTBUS = "y";
          PCIE_MEDIATEK_GEN3 = "y";
          PCIE_PME = "y";
          PCI_DEBUG = "y";
          PCI_DOMAINS = "y";
          PCI_DOMAINS_GENERIC = "y";
          PCI_MSI = "y";
          PCS_MTK_LYNXI = "y";
          PCS_MTK_USXGMII = "y";
          PERF_EVENTS = "y";
          PER_VMA_LOCK = "y";
          PHYLIB = "y";
          PHYLIB_LEDS = "y";
          PHYLINK = "y";
          PHYS_ADDR_T_64BIT = "y";
          PHY_MTK_TPHY = "y";
          PHY_MTK_XFI_TPHY = "y";
          PHY_MTK_XSPHY = "y";
          PINCTRL = "y";
          PINCTRL_MT7981 = "y";
          PINCTRL_MT7986 = "y";
          PINCTRL_MT7988 = "y";
          PINCTRL_MTK_MOORE = "y";
          PINCTRL_MTK_V2 = "y";
          PM = "y";
          PM_CLK = "y";
          PM_DEVFREQ = "y";
          PM_DEVFREQ_EVENT = "y";
          PM_GENERIC_DOMAINS = "y";
          PM_GENERIC_DOMAINS_OF = "y";
          PM_OPP = "y";
          POLYNOMIAL = "y";
          POSIX_CPU_TIMERS_TASK_WORK = "y";
          POWER_RESET = "y";
          POWER_RESET_SYSCON = "y";
          POWER_SUPPLY = "y";
          PREEMPT_NONE_BUILD = "y";
          PRINTK_TIME = "y";
          PSTORE = "y";
          PSTORE_COMPRESS = "y";
          PSTORE_CONSOLE = "y";
          PSTORE_PMSG = "y";
          PSTORE_RAM = "y";
          PTP_1588_CLOCK_OPTIONAL = "y";
          PWM = "y";
          PWM_MEDIATEK = "y";
          QUEUED_RWLOCKS = "y";
          QUEUED_SPINLOCKS = "y";
          RANDSTRUCT_NONE = "y";
          RAS = "y";
          RATIONAL = "y";
          REALTEK_PHY = "y";
          REED_SOLOMON = "y";
          REED_SOLOMON_DEC8 = "y";
          REED_SOLOMON_ENC8 = "y";
          REGMAP = "y";
          REGMAP_I2C = "y";
          REGMAP_MMIO = "y";
          REGULATOR = "y";
          REGULATOR_FIXED_VOLTAGE = "y";
          REGULATOR_MT6380 = "y";
          REGULATOR_RT5190A = "y";
          RESET_CONTROLLER = "y";
          RESET_TI_SYSCON = "y";
          RFS_ACCEL = "y";
          RODATA_FULL_DEFAULT_ENABLED = "y";
          RPS = "y";
          RTC_CLASS = "y";
          RTC_DRV_MT7622 = "y";
          RTC_I2C_AND_SPI = "y";
          RWSEM_SPIN_ON_OWNER = "y";
          SCHED_MC = "y";
          SCSI = "y";
          SCSI_COMMON = "y";
          SERIAL_8250_FSL = "y";
          SERIAL_8250_MT6577 = "y";
          SERIAL_8250_NR_UARTS = "3";
          SERIAL_8250_RUNTIME_UARTS = "3";
          SERIAL_DEV_BUS = "y";
          SERIAL_DEV_CTRL_TTYPORT = "y";
          SERIAL_MCTRL_GPIO = "y";
          SERIAL_OF_PLATFORM = "y";
          SGL_ALLOC = "y";
          SG_POOL = "y";
          SMP = "y";
          SOCK_RX_QUEUE_MAPPING = "y";
          SOFTIRQ_ON_OWN_STACK = "y";
          SPARSEMEM = "y";
          SPARSEMEM_EXTREME = "y";
          SPARSEMEM_VMEMMAP = "y";
          SPARSEMEM_VMEMMAP_ENABLE = "y";
          SPARSE_IRQ = "y";
          SPI = "y";
          SPI_DYNAMIC = "y";
          SPI_MASTER = "y";
          SPI_MEM = "y";
          SPI_MT65XX = "y";
          SPI_MTK_SNFI = "y";
          #SQUASHFS_DECOMP_MULTI_PERCPU="y";
          SWIOTLB = "y";
          SWPHY = "y";
          SYSCTL_EXCEPTION_TRACE = "y";
          THERMAL = "y";
          THERMAL_DEFAULT_GOV_STEP_WISE = "y";
          THERMAL_EMERGENCY_POWEROFF_DELAY_MS = "0";
          THERMAL_GOV_BANG_BANG = "y";
          THERMAL_GOV_FAIR_SHARE = "y";
          THERMAL_GOV_STEP_WISE = "y";
          THERMAL_GOV_USER_SPACE = "y";
          THERMAL_HWMON = "y";
          THERMAL_OF = "y";
          THREAD_INFO_IN_TASK = "y";
          TICK_CPU_ACCOUNTING = "y";
          TIMER_OF = "y";
          TIMER_PROBE = "y";
          TRACE_IRQFLAGS_NMI_SUPPORT = "y";
          TREE_RCU = "y";
          TREE_SRCU = "y";
          UBIFS_FS = "y";
          UIMAGE_FIT_BLK = "y";
          USB_SUPPORT = "y";
          VMAP_STACK = "y";
          WATCHDOG_CORE = "y";
          WATCHDOG_PRETIMEOUT_DEFAULT_GOV_PANIC = "y";
          WATCHDOG_PRETIMEOUT_GOV = "y";
          WATCHDOG_PRETIMEOUT_GOV_PANIC = "y";
          WATCHDOG_PRETIMEOUT_GOV_SEL = "m";
          WATCHDOG_SYSFS = "y";
          XPS = "y";
          XXHASH = "y";
          ZLIB_DEFLATE = "y";
          ZLIB_INFLATE = "y";
          ZONE_DMA32 = "y";
          ZSTD_COMMON = "y";
          ZSTD_COMPRESS = "y";
          ZSTD_DECOMPRESS = "y";
          EFI_PARTITION = "y";
        };
        conditionalConfig.WLAN = {
          MT7915E = "m";
          MT798X_WMAC = "y";
        };
      };
      filesystem = dir { lib = dir { firmware = dir { mediatek = symlink firmware; }; }; };
      # UART0 and baud rate: https://github.com/openwrt/openwrt/blob/8303e9b2a004a6c3754aaa1edb32cfc7c0cfe55b/target/linux/mediatek/dts/mt7986a-glinet-gl-mt6000.dts#L21-L26
      boot.commandLine = [ "console=ttyS0,115200" ];
      boot.imageFormat = "fit";
      # Liminix RAM staging area, 128 MiB above the Filogic kernel address.
      # The board has 1 GiB of RAM starting at 0x40000000:
      # https://github.com/openwrt/openwrt/blob/8303e9b2a004a6c3754aaa1edb32cfc7c0cfe55b/package/boot/uboot-mediatek/patches/436-add-glinet-mt6000.patch#L21-L23
      # modules/outputs/tftpboot.nix places the phram rootfs, DTB and image here.
      boot.tftp.loadAddress = lim.parseInt "0x50000000";
      hardware = {
        defaultOutput = "factory";
        # RAM boot convention in modules/outputs/tftpboot.nix (binsize64k and phram0).
        rootDevice = "/dev/mtdblock0";
        flash.eraseBlockSize = 65536; # phram erase size
        # GL-MT6000 inherits the Filogic default kernel load address:
        # https://github.com/openwrt/openwrt/blob/8303e9b2a004a6c3754aaa1edb32cfc7c0cfe55b/target/linux/mediatek/image/Makefile#L14-L24
        loadAddress = lim.parseInt "0x48000000";
        # OpenWrt FIT defaults the entry point to KERNEL_LOADADDR:
        # https://github.com/openwrt/openwrt/blob/8303e9b2a004a6c3754aaa1edb32cfc7c0cfe55b/include/image-commands.mk#L448
        entryPoint = config.hardware.loadAddress;
        dts = {
          src = "${openwrt.src}/target/linux/mediatek/dts/mt7986a-glinet-gl-mt6000.dts";
          includes = [ ./ramboot.dtsi ];
          includePaths = [
            "${openwrt.src}/target/linux/mediatek/dts"
            "${config.system.outputs.kernel.modulesupport}/arch/arm64/boot/dts/mediatek"
          ];
        };
        networkInterfaces =
          let
            inherit (config.system.service.network) link;
            wifi = pkgs.kmodloader.override {
              targets = [ "mt7915e" ];
              inherit (config.system.outputs) kernel;
            };
          in
          rec {
            lan = lan1;
            # https://github.com/openwrt/openwrt/blob/8303e9b2a004a6c3754aaa1edb32cfc7c0cfe55b/target/linux/mediatek/filogic/base-files/etc/board.d/02_network#L98-L104
            wan = link.build { ifname = "eth1"; };
            lan1 = link.build { ifname = "lan1"; };
            lan2 = link.build { ifname = "lan2"; };
            lan3 = link.build { ifname = "lan3"; };
            lan4 = link.build { ifname = "lan4"; };
            lan5 = link.build { ifname = "lan5"; };
            wlan = link.build {
              ifname = "wlan0";
              dependencies = [ wifi ];
            };
            wlan5 = link.build {
              ifname = "wlan1";
              dependencies = [ wifi ];
            };
          };
      };
    };
}
