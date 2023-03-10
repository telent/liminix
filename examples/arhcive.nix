# This is not part of Liminix per se. This is a "scratchpad"
# configuration for a device I'm testing with.
#
# Parts of it do do things that Liminix eventually needs to do, but
# don't look in here for solutions - just for identifying the
# problems.
{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = import ./extneder-secrets.nix;
  inherit
    (pkgs.liminix.networking)
    address
    udhcpc
    interface
    route
  ;
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) writeText dropbear ifwait serviceFns
    ;
in rec {
  boot = {
    tftp = {
      enable = true;
      serverip = "192.168.8.148";
      ipaddr = "192.168.8.251";
    };
  };

  imports = [
    ../modules/tftpboot.nix
    ../modules/wlan.nix
    # ./modules/flashable.nix
  ];

  hostname = "arhcive";

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
      PARTITION_ADVANCED = "y";
      MSDOS_PARTITION = "y";
      EFI_PARTITION = "y";
      EXT4_FS = "y";
      EXT4_USE_FOR_EXT2 = "y";
      FS_ENCRYPTION = "y";
    };
  };

  services.dhcpc = (udhcpc config.hardware.networkInterfaces.lan {
    dependencies = [ config.services.hostname ];
  }) // { inherit (config.hardware.networkInterfaces.lan) device; };

  services.sshd = longrun {
    name = "sshd";
    run = ''
      mkdir -p /run/dropbear
      ${dropbear}/bin/dropbear -E -P /run/dropbear.pid -R -F
    '';
  };

  services.resolvconf = oneshot rec {
    dependencies = [ services.dhcpc ];
    name = "resolvconf";
    up = ''
      . ${serviceFns}
      ( in_outputs ${name}
      for i in $(output ${services.dhcpc} dns); do
        echo "nameserver $i" > resolv.conf
      done
      )
    '';
    down = ''
      rm -rf /run/service-state/${name}/
    '';
  };
  filesystem = dir {
    etc = dir {
      "resolv.conf" = symlink "${services.resolvconf}/.outputs/resolv.conf";
    };
    srv = dir {};
  };

  services.defaultroute4 = route {
    name = "defaultroute";
    via = "$(output ${services.dhcpc} router)";
    target = "default";
    dependencies = [services.dhcpc];
  };

  programs.busybox  = {
    applets = ["blkid" "lsusb" "tar"];
    options = {
      FEATURE_LS_TIMESTAMPS = "y";
      FEATURE_LS_SORTFILES = "y";
      FEATURE_BLKID_TYPE = "y";
      FEATURE_MOUNT_FLAGS = "y";
      FEATURE_MOUNT_LABEL = "y";
      FEATURE_VOLUMEID_EXT = "y";
    };
  };

  services.mount_external_disk = oneshot {
    name = "mount_external_disk";
    up = "mount -t ext4 LABEL=backup-disk /srv";
    down = "umount /srv";
  };

  services.rsync =
    let
      secrets_file = oneshot rec {
        name = "rsync-secrets";
        up = ''
          . ${serviceFns}
          (in_outputs ${name}
           echo  "backup:${secrets.rsync_secret}" > secrets)
        '';
        down = "true";
      };
      configFile = writeText "rsync.conf" ''
        pid file = /run/rsyncd.pid
        uid = store
        [srv]
          path = /srv
          use chroot = yes
          auth users = backup
          read only = false
          secrets file = ${secrets_file}/.outputs/secrets
      '';
    in longrun {
      name = "rsync";
      run = ''
        ${pkgs.rsync}/bin/rsync --no-detach --daemon  --config=${configFile}
      '';
      dependencies = [
        secrets_file
        services.mount_external_disk
        config.hardware.networkInterfaces.lan
      ] ;
    };

    services.default = target {
    name = "default";
    contents =
      let links = config.hardware.networkInterfaces;
      in with config.services; [
        links.lo links.eth links.wlan
        defaultroute4
        resolvconf
        sshd
        rsync
      ];
  };
  users.root.passwd = lib.mkForce secrets.root_password;

  users.store = {
    uid=500; gid=500; gecos="Storage owner"; dir="/srv";
    shell="/dev/null"; # authorizedKeys = [];
  };

  defaultProfile.packages = with pkgs; [e2fsprogs strace tcpdump ];
}
