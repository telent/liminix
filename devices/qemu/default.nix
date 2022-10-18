# This "device" generates images that can be used with the QEMU
# emulator. The default output is a directory containing separate
# kernel (uncompressed vmlinux) and initrd (squashfs) images

{
  system = {
    crossSystem = {
      config = "mips-unknown-linux-musl";
      gcc = {
        abi = "32";
        arch = "mips32";          # maybe mips_24kc-
      };
    };
  };

  overlay = final: prev:
    let inherit (final) fetchFromGitHub;
    in {
      sources = {
        kernel =  fetchFromGitHub {
          name = "kernel-source";
          owner = "torvalds";
          repo = "linux";
          rev = "3d7cb6b04c3f3115719235cc6866b10326de34cd";  # v5.19
          hash = "sha256-OVsIRScAnrPleW1vbczRAj5L/SGGht2+GnvZJClMUu4=";
        };
      };
    };

  kernel = {
    config = {
      SYSVIPC= "y";
      NO_HZ= "y";
      HIGH_RES_TIMERS= "y";
      LOG_BUF_SHIFT = "15";
      NAMESPACES= "y";
      RELAY= "y";
      EXPERT= "y";
      PERF_EVENTS= "y";
      COMPAT_BRK= "n";
      SLAB= "y";
      MIPS_MALTA= "y";
      CPU_LITTLE_ENDIAN= "n";
      CPU_BIG_ENDIAN= "y";
      CPU_MIPS32_R2= "y";
      PAGE_SIZE_16KB= "y";
      NR_CPUS= "1";
      HZ_100= "y";
      PCI= "y";
      VIRTUALIZATION= "y";
      KVM_MIPS_DEBUG_COP0_COUNTERS= "y";
      MODULES= "y";
      MODULE_UNLOAD= "y";
      MODVERSIONS= "y";
      MODULE_SRCVERSION_ALL= "y";
      NET= "y";
      PACKET= "y";
      UNIX= "y";
      NET_KEY= "y";
      NET_KEY_MIGRATE= "y";
      INET= "y";
      IP_MULTICAST= "y";
      IP_ADVANCED_ROUTER= "y";
      IP_MULTIPLE_TABLES= "y";
      IP_ROUTE_MULTIPATH= "y";
      IP_ROUTE_VERBOSE= "y";
      IP_PNP= "y";
      IP_PNP_DHCP= "y";
      IP_PNP_BOOTP= "y";
      IP_MROUTE= "y";
      IP_PIMSM_V1= "y";
      IP_PIMSM_V2= "y";
      SYN_COOKIES= "y";
      TCP_MD5SIG= "y";
      IPV6_ROUTER_PREF= "y";
      IPV6_ROUTE_INFO= "y";
      IPV6_OPTIMISTIC_DAD= "y";
      IPV6_MROUTE= "y";
      IPV6_PIMSM_V2= "y";
      NETWORK_SECMARK= "y";
      NETFILTER= "y";
      NF_CONNTRACK_SECMARK= "y";
      NF_CONNTRACK_EVENTS= "y";
      IP_VS_IPV6= "y";
      IP_VS_PROTO_TCP= "y";
      IP_VS_PROTO_UDP= "y";
      IP_VS_PROTO_ESP= "y";
      IP_VS_PROTO_AH= "y";
      VLAN_8021Q_GVRP= "y";
      IPDDP_ENCAP= "y";
      NET_SCHED= "y";
      NET_CLS_ACT= "y";
      NET_ACT_POLICE= "y";
      GACT_PROB= "y";
      MTD= "y";
      MTD_BLOCK= "y";
      MTD_CFI= "y";
      MTD_CFI_INTELEXT= "y";
      MTD_CFI_AMDSTD= "y";
      MTD_CFI_STAA= "y";
      MTD_PHYSMAP_OF= "y";
      BLK_DEV_RAM= "y";
      BLK_DEV_SD= "y";
      BLK_DEV_SR= "y";
      SCSI_CONSTANTS= "y";
      SCSI_LOGGING= "y";
      SCSI_SCAN_ASYNC= "y";
      AIC7XXX_RESET_DELAY_MS="15000";
      AIC7XXX_DEBUG_ENABLE= "n";
      ATA= "y";
      ATA_PIIX= "y";
      PATA_OLDPIIX= "y";
      PATA_MPIIX= "y";
      ATA_GENERIC= "y";
      PATA_LEGACY= "y";
      MD= "y";
      NETDEVICES= "y";
      PCNET32= "y";
      IPW2100_MONITOR= "y";
      HOSTAP_FIRMWARE= "y";
      HOSTAP_FIRMWARE_NVRAM= "y";
      INPUT_MOUSEDEV= "y";
      SERIAL_8250= "y";
      SERIAL_8250_CONSOLE= "y";
      POWER_RESET= "y";
      POWER_RESET_PIIX4_POWEROFF= "y";
      POWER_RESET_SYSCON= "y";
      HWMON= "n";
      FB= "y";
      FB_CIRRUS= "y";
      VGA_CONSOLE= "n";
      FRAMEBUFFER_CONSOLE= "y";
      RTC_CLASS= "y";
      RTC_DRV_CMOS= "y";
      EXT2_FS= "y";
      EXT3_FS= "y";
      JFS_POSIX_ACL= "y";
      JFS_SECURITY= "y";
      QUOTA= "y";
      QFMT_V2= "y";
      JOLIET= "y";
      ZISOFS= "y";
      PROC_KCORE= "y";
      TMPFS= "y";
      CONFIGFS_FS= "y";
      JFFS2_FS_XATTR= "y";
      JFFS2_COMPRESSION_OPTIONS= "y";
      JFFS2_RUBIN= "y";
      # NFS_FS= "y";
      # ROOT_NFS= "y";
      # NFSD= "y";
      # NFSD_V3= "y";
      CRYPTO_HMAC= "y";
      RCU_CPU_STALL_TIMEOUT = "60";
      ENABLE_DEFAULT_TRACERS = "y";

      CFG80211= "y";
      MAC80211= "y";
      MAC80211_MESH= "y";
      RFKILL= "y";
      WLAN = "y";
      MAC80211_HWSIM = "y";
      SQUASHFS = "y";
      SQUASHFS_XZ = "y";
      VIRTIO_PCI = "y";
      VIRTIO_BLK = "y";
      VIRTIO_NET = "y";
    };
  };
  outputs.default = "directory";
}