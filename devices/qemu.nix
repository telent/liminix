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
  kernel = {
    checkedConfig = {
      "BINFMT_SCRIPT" = "y";
    };
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
      CPU_BIG_ENDIAN= "n";
      CPU_MIPS32_R2= "y";
      PAGE_SIZE_16KB= "y";
      NR_CPUS= "1";
      HZ_100= "y";
      PCI= "y";
      VIRTUALIZATION= "y";
      KVM= "m";
      KVM_MIPS_DEBUG_COP0_COUNTERS= "y";
      VHOST_NET= "m";
      MODULES= "y";
      MODULE_UNLOAD= "y";
      MODVERSIONS= "y";
      MODULE_SRCVERSION_ALL= "y";
      NET= "y";
      PACKET= "y";
      UNIX= "y";
      XFRM_USER= "m";
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
      NET_IPIP= "m";
      IP_MROUTE= "y";
      IP_PIMSM_V1= "y";
      IP_PIMSM_V2= "y";
      SYN_COOKIES= "y";
      INET_AH= "m";
      INET_ESP= "m";
      INET_IPCOMP= "m";
      INET_XFRM_MODE_TRANSPORT= "m";
      INET_XFRM_MODE_TUNNEL= "m";
      TCP_MD5SIG= "y";
      IPV6_ROUTER_PREF= "y";
      IPV6_ROUTE_INFO= "y";
      IPV6_OPTIMISTIC_DAD= "y";
      INET6_AH= "m";
      INET6_ESP= "m";
      INET6_IPCOMP= "m";
      IPV6_TUNNEL= "m";
      IPV6_MROUTE= "y";
      IPV6_PIMSM_V2= "y";
      NETWORK_SECMARK= "y";
      NETFILTER= "y";
      NF_CONNTRACK= "m";
      NF_CONNTRACK_SECMARK= "y";
      NF_CONNTRACK_EVENTS= "y";
      NF_CONNTRACK_AMANDA= "m";
      NF_CONNTRACK_FTP= "m";
      NF_CONNTRACK_H323= "m";
      NF_CONNTRACK_IRC= "m";
      NF_CONNTRACK_PPTP= "m";
      NF_CONNTRACK_SANE= "m";
      NF_CONNTRACK_SIP= "m";
      NF_CONNTRACK_TFTP= "m";
      NF_CT_NETLINK= "m";
      NETFILTER_XT_TARGET_CLASSIFY= "m";
      NETFILTER_XT_TARGET_CONNMARK= "m";
      NETFILTER_XT_TARGET_MARK= "m";
      NETFILTER_XT_TARGET_NFLOG= "m";
      NETFILTER_XT_TARGET_NFQUEUE= "m";
      NETFILTER_XT_TARGET_TPROXY= "m";
      NETFILTER_XT_TARGET_TRACE= "m";
      NETFILTER_XT_TARGET_SECMARK= "m";
      NETFILTER_XT_TARGET_TCPMSS= "m";
      NETFILTER_XT_TARGET_TCPOPTSTRIP= "m";
      NETFILTER_XT_MATCH_COMMENT= "m";
      NETFILTER_XT_MATCH_CONNBYTES= "m";
      NETFILTER_XT_MATCH_CONNLIMIT= "m";
      NETFILTER_XT_MATCH_CONNMARK= "m";
      NETFILTER_XT_MATCH_CONNTRACK= "m";
      NETFILTER_XT_MATCH_DCCP= "m";
      NETFILTER_XT_MATCH_ESP= "m";
      NETFILTER_XT_MATCH_HASHLIMIT= "m";
      NETFILTER_XT_MATCH_HELPER= "m";
      NETFILTER_XT_MATCH_IPRANGE= "m";
      NETFILTER_XT_MATCH_LENGTH= "m";
      NETFILTER_XT_MATCH_LIMIT= "m";
      NETFILTER_XT_MATCH_MAC= "m";
      NETFILTER_XT_MATCH_MARK= "m";
      NETFILTER_XT_MATCH_MULTIPORT= "m";
      NETFILTER_XT_MATCH_OWNER= "m";
      NETFILTER_XT_MATCH_POLICY= "m";
      NETFILTER_XT_MATCH_PKTTYPE= "m";
      NETFILTER_XT_MATCH_QUOTA= "m";
      NETFILTER_XT_MATCH_RATEEST= "m";
      NETFILTER_XT_MATCH_REALM= "m";
      NETFILTER_XT_MATCH_RECENT= "m";
      NETFILTER_XT_MATCH_SOCKET= "m";
      NETFILTER_XT_MATCH_STATE= "m";
      NETFILTER_XT_MATCH_STATISTIC= "m";
      NETFILTER_XT_MATCH_STRING= "m";
      NETFILTER_XT_MATCH_TCPMSS= "m";
      NETFILTER_XT_MATCH_TIME= "m";
      NETFILTER_XT_MATCH_U32= "m";
      IP_VS= "m";
      IP_VS_IPV6= "y";
      IP_VS_PROTO_TCP= "y";
      IP_VS_PROTO_UDP= "y";
      IP_VS_PROTO_ESP= "y";
      IP_VS_PROTO_AH= "y";
      IP_VS_RR= "m";
      IP_VS_WRR= "m";
      IP_VS_LC= "m";
      IP_VS_WLC= "m";
      IP_VS_LBLC= "m";
      IP_VS_LBLCR= "m";
      IP_VS_DH= "m";
      IP_VS_SH= "m";
      IP_VS_SED= "m";
      IP_VS_NQ= "m";
      IP_NF_IPTABLES= "m";
      IP_NF_MATCH_AH= "m";
      IP_NF_MATCH_ECN= "m";
      IP_NF_MATCH_TTL= "m";
      IP_NF_FILTER= "m";
      IP_NF_TARGET_REJECT= "m";
      IP_NF_MANGLE= "m";
      IP_NF_TARGET_CLUSTERIP= "m";
      IP_NF_TARGET_ECN= "m";
      IP_NF_TARGET_TTL= "m";
      IP_NF_RAW= "m";
      IP_NF_ARPTABLES= "m";
      IP_NF_ARPFILTER= "m";
      IP_NF_ARP_MANGLE= "m";
      IP6_NF_MATCH_AH= "m";
      IP6_NF_MATCH_EUI64= "m";
      IP6_NF_MATCH_FRAG= "m";
      IP6_NF_MATCH_OPTS= "m";
      IP6_NF_MATCH_HL= "m";
      IP6_NF_MATCH_IPV6HEADER= "m";
      IP6_NF_MATCH_MH= "m";
      IP6_NF_MATCH_RT= "m";
      IP6_NF_TARGET_HL= "m";
      IP6_NF_FILTER= "m";
      IP6_NF_TARGET_REJECT= "m";
      IP6_NF_MANGLE= "m";
      IP6_NF_RAW= "m";
      BRIDGE_NF_EBTABLES= "m";
      BRIDGE_EBT_BROUTE= "m";
      BRIDGE_EBT_T_FILTER= "m";
      BRIDGE_EBT_T_NAT= "m";
      BRIDGE_EBT_802_3= "m";
      BRIDGE_EBT_AMONG= "m";
      BRIDGE_EBT_ARP= "m";
      BRIDGE_EBT_IP= "m";
      BRIDGE_EBT_IP6= "m";
      BRIDGE_EBT_LIMIT= "m";
      BRIDGE_EBT_MARK= "m";
      BRIDGE_EBT_PKTTYPE= "m";
      BRIDGE_EBT_STP= "m";
      BRIDGE_EBT_VLAN= "m";
      BRIDGE_EBT_ARPREPLY= "m";
      BRIDGE_EBT_DNAT= "m";
      BRIDGE_EBT_MARK_T= "m";
      BRIDGE_EBT_REDIRECT= "m";
      BRIDGE_EBT_SNAT= "m";
      BRIDGE_EBT_LOG= "m";
      BRIDGE_EBT_NFLOG= "m";
      IP_SCTP= "m";
      BRIDGE= "m";
      VLAN_8021Q= "m";
      VLAN_8021Q_GVRP= "y";
      ATALK= "m";
      DEV_APPLETALK= "m";
      IPDDP= "m";
      IPDDP_ENCAP= "y";
      PHONET= "m";
      NET_SCHED= "y";
      NET_SCH_CBQ= "m";
      NET_SCH_HTB= "m";
      NET_SCH_HFSC= "m";
      NET_SCH_PRIO= "m";
      NET_SCH_RED= "m";
      NET_SCH_SFQ= "m";
      NET_SCH_TEQL= "m";
      NET_SCH_TBF= "m";
      NET_SCH_GRED= "m";
      NET_SCH_DSMARK= "m";
      NET_SCH_NETEM= "m";
      NET_SCH_INGRESS= "m";
      NET_CLS_BASIC= "m";
      NET_CLS_TCINDEX= "m";
      NET_CLS_ROUTE4= "m";
      NET_CLS_FW= "m";
      NET_CLS_U32= "m";
      NET_CLS_RSVP= "m";
      NET_CLS_RSVP6= "m";
      NET_CLS_FLOW= "m";
      NET_CLS_ACT= "y";
      NET_ACT_POLICE= "y";
      NET_ACT_GACT= "m";
      GACT_PROB= "y";
      NET_ACT_MIRRED= "m";
      NET_ACT_IPT= "m";
      NET_ACT_NAT= "m";
      NET_ACT_PEDIT= "m";
      NET_ACT_SIMP= "m";
      NET_ACT_SKBEDIT= "m";
      DEVTMPFS= "y";
      CONNECTOR= "m";
      MTD= "y";
      MTD_BLOCK= "y";
      MTD_OOPS= "m";
      MTD_CFI= "y";
      MTD_CFI_INTELEXT= "y";
      MTD_CFI_AMDSTD= "y";
      MTD_CFI_STAA= "y";
      MTD_PHYSMAP_OF= "y";
      MTD_UBI= "m";
      MTD_UBI_GLUEBI= "m";
      BLK_DEV_FD= "m";
      BLK_DEV_LOOP= "m";
      BLK_DEV_CRYPTOLOOP= "m";
      BLK_DEV_NBD= "m";
      BLK_DEV_RAM= "y";
      CDROM_PKTCDVD= "m";
      ATA_OVER_ETH= "m";
      RAID_ATTRS= "m";
      BLK_DEV_SD= "y";
      CHR_DEV_ST= "m";
      CHR_DEV_OSST= "m";
      BLK_DEV_SR= "y";
      CHR_DEV_SG= "m";
      SCSI_CONSTANTS= "y";
      SCSI_LOGGING= "y";
      SCSI_SCAN_ASYNC= "y";
      SCSI_FC_ATTRS= "m";
      ISCSI_TCP= "m";
      BLK_DEV_3W_XXXX_RAID= "m";
      SCSI_3W_9XXX= "m";
      SCSI_ACARD= "m";
      SCSI_AACRAID= "m";
      SCSI_AIC7XXX= "m";
      AIC7XXX_RESET_DELAY_MS="15000";
      AIC7XXX_DEBUG_ENABLE= "n";
      ATA= "y";
      ATA_PIIX= "y";
      PATA_IT8213= "m";
      PATA_OLDPIIX= "y";
      PATA_MPIIX= "y";
      ATA_GENERIC= "y";
      PATA_LEGACY= "y";
      MD= "y";
      BLK_DEV_MD= "m";
      MD_LINEAR= "m";
      MD_RAID0= "m";
      MD_RAID1= "m";
      MD_RAID10= "m";
      MD_RAID456= "m";
      MD_MULTIPATH= "m";
      MD_FAULTY= "m";
      BLK_DEV_DM= "m";
      DM_CRYPT= "m";
      DM_SNAPSHOT= "m";
      DM_MIRROR= "m";
      DM_ZERO= "m";
      DM_MULTIPATH= "m";
      NETDEVICES= "y";
      BONDING= "m";
      DUMMY= "m";
      EQUALIZER= "m";
      IFB= "m";
      MACVLAN= "m";
      TUN= "m";
      VETH= "m";
      PCNET32= "y";
      CHELSIO_T3= "m";
      AX88796= "m";
      NETXEN_NIC= "m";
      TC35815= "m";
      BROADCOM_PHY= "m";
      CICADA_PHY= "m";
      DAVICOM_PHY= "m";
      ICPLUS_PHY= "m";
      LXT_PHY= "m";
      MARVELL_PHY= "m";
      QSEMI_PHY= "m";
      REALTEK_PHY= "m";
      SMSC_PHY= "m";
      VITESSE_PHY= "m";
      ATMEL= "m";
      PCI_ATMEL= "m";
      IPW2100= "m";
      IPW2100_MONITOR= "y";
      HOSTAP= "m";
      HOSTAP_FIRMWARE= "y";
      HOSTAP_FIRMWARE_NVRAM= "y";
      HOSTAP_PLX= "m";
      HOSTAP_PCI= "m";
      PRISM54= "m";
      LIBERTAS= "m";
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
      HID= "m";
      RTC_CLASS= "y";
      RTC_DRV_CMOS= "y";
      UIO= "m";
      UIO_CIF= "m";
      EXT2_FS= "y";
      EXT3_FS= "y";
      JFS_FS= "m";
      JFS_POSIX_ACL= "y";
      JFS_SECURITY= "y";
      QUOTA= "y";
      QFMT_V2= "y";
      FUSE_FS= "m";
      ISO9660_FS= "m";
      JOLIET= "y";
      ZISOFS= "y";
      UDF_FS= "m";
      MSDOS_FS= "m";
      VFAT_FS= "m";
      PROC_KCORE= "y";
      TMPFS= "y";
      CONFIGFS_FS= "y";
      BEFS_FS= "m";
      BFS_FS= "m";
      EFS_FS= "m";
      JFFS2_FS= "m";
      JFFS2_FS_XATTR= "y";
      JFFS2_COMPRESSION_OPTIONS= "y";
      JFFS2_RUBIN= "y";
      CRAMFS= "m";
      VXFS_FS= "m";
      MINIX_FS= "m";
      ROMFS_FS= "m";
      SYSV_FS= "m";
      UFS_FS= "m";
      # NFS_FS= "y";
      # ROOT_NFS= "y";
      # NFSD= "y";
      # NFSD_V3= "y";
      NLS_CODEPAGE_437= "m";
      NLS_CODEPAGE_737= "m";
      NLS_CODEPAGE_775= "m";
      NLS_CODEPAGE_850= "m";
      NLS_CODEPAGE_852= "m";
      NLS_CODEPAGE_855= "m";
      NLS_CODEPAGE_857= "m";
      NLS_CODEPAGE_860= "m";
      NLS_CODEPAGE_861= "m";
      NLS_CODEPAGE_862= "m";
      NLS_CODEPAGE_863= "m";
      NLS_CODEPAGE_864= "m";
      NLS_CODEPAGE_865= "m";
      NLS_CODEPAGE_866= "m";
      NLS_CODEPAGE_869= "m";
      NLS_CODEPAGE_936= "m";
      NLS_CODEPAGE_950= "m";
      NLS_CODEPAGE_932= "m";
      NLS_CODEPAGE_949= "m";
      NLS_CODEPAGE_874= "m";
      NLS_ISO8859_8= "m";
      NLS_CODEPAGE_1250= "m";
      NLS_CODEPAGE_1251= "m";
      NLS_ASCII= "m";
      NLS_ISO8859_1= "m";
      NLS_ISO8859_2= "m";
      NLS_ISO8859_3= "m";
      NLS_ISO8859_4= "m";
      NLS_ISO8859_5= "m";
      NLS_ISO8859_6= "m";
      NLS_ISO8859_7= "m";
      NLS_ISO8859_9= "m";
      NLS_ISO8859_13= "m";
      NLS_ISO8859_14= "m";
      NLS_ISO8859_15= "m";
      NLS_KOI8_R= "m";
      NLS_KOI8_U= "m";
      CRYPTO_CRYPTD= "m";
      CRYPTO_LRW= "m";
      CRYPTO_PCBC= "m";
      CRYPTO_HMAC= "y";
      CRYPTO_XCBC= "m";
      CRYPTO_MD4= "m";
      CRYPTO_SHA512= "m";
      CRYPTO_TGR192= "m";
      CRYPTO_WP512= "m";
      CRYPTO_ANUBIS= "m";
      CRYPTO_BLOWFISH= "m";
      CRYPTO_CAMELLIA= "m";
      CRYPTO_CAST5= "m";
      CRYPTO_CAST6= "m";
      CRYPTO_FCRYPT= "m";
      CRYPTO_KHAZAD= "m";
      CRYPTO_SERPENT= "m";
      CRYPTO_TEA= "m";
      CRYPTO_TWOFISH= "m";
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
