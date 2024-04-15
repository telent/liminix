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
    "${modulesPath}/mdevd.nix"
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

  services.watch_mount_srv =
    let
      node = "/dev/disk/by-partlabel/backup-disk";
      mount = oneshot {
        name = "mount-srv";
        up = "mount -t ext2 ${node} /srv";
        down = "umount /srv";
      };
    in longrun {
      name = "mount_srv";
      run = ''
        ${pkgs.uevent-watch}/bin/uevent-watch -s ${mount.name} -n ${node} partname=backup-disk devtype=partition
      '';
      dependencies = [ config.services.mdevd ];
      buildInputs = [ mount ];
    };
}
