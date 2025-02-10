{
  config,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (pkgs.pseudofile) dir;

  svc = config.system.service;

in
rec {
  imports = [
    "${modulesPath}/dhcp6c"
    "${modulesPath}/dnsmasq"
    "${modulesPath}/firewall"
    "${modulesPath}/hostapd"
    "${modulesPath}/network"
    "${modulesPath}/ssh"
    "${modulesPath}/mount"
    "${modulesPath}/mdevd.nix"
  ];

  filesystem = dir { srv = dir { }; };

  kernel = {
    config = {
      USB = "y";
      USB_EHCI_HCD = "y";
      USB_EHCI_HCD_PLATFORM = "y";
      USB_OHCI_HCD = "y";
      USB_OHCI_HCD_PLATFORM = "y";
      USB_SUPPORT = "y";
      USB_COMMON = "y";
      USB_STORAGE = "y";
      USB_STORAGE_DEBUG = "n";
      USB_UAS = "y";
      USB_ANNOUNCE_NEW_DEVICES = "y";
      SCSI = "y";
      BLK_DEV_SD = "y";
      USB_PRINTER = "y";
      MSDOS_PARTITION = "y";
      EFI_PARTITION = "y";
      EXT4_FS = "y";
      EXT4_USE_FOR_EXT2 = "y";
      FS_ENCRYPTION = "y";
    };
  };

  rootfsType = "jffs2";
  hostname = "inout";

  services.mount_backup_disk = svc.mount.build {
    partlabel = "backup-disk";
    mountpoint = "/srv";
    fstype = "ext4";
  };
}
