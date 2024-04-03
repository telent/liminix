{ config, pkgs, lib, modulesPath, ... } :
let
  inherit (pkgs.liminix.services) bundle oneshot longrun;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) serviceFns;

  svc = config.system.service;

in rec {
  imports = [
    "${modulesPath}/dhcp6c"
    "${modulesPath}/dnsmasq"
    "${modulesPath}/firewall"
    "${modulesPath}/hostapd"
    "${modulesPath}/network"
    "${modulesPath}/ssh"
    "${modulesPath}/mount"
  ];

  filesystem = dir { srv = dir {}; };

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

  services.mount_external_disk = svc.mount.build {
    device = "LABEL=backup-disk";
    mountpoint = "/srv";
    fstype = "ext4";
  };

  services.sshd = svc.ssh.build { };

  defaultProfile.packages = with pkgs; [
    min-collect-garbage
    tcpdump
  ];
}
