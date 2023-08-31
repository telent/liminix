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
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) writeText dropbear ifwait serviceFns;
  svc = config.system.service;
in rec {
  boot = {
    tftp = {
      serverip = "192.168.8.148";
      ipaddr = "192.168.8.251";
    };
  };

  imports = [
    ../modules/standard.nix
    ../modules/wlan.nix
    ../modules/network
    ../modules/vlan
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

  services.dhcpc =
    let iface = config.hardware.networkInterfaces.lan;
    in svc.network.dhcp.client.build {
      interface = iface;
      dependencies = [ config.services.hostname ];
    };

  services.sshd = svc.ssh.build { };

  services.watchdog =
    let
      watched = with config.services ; [ sshd dhcpc ];
      spinupGrace = 60;
      script = pkgs.writeAshScript "gaspode" {
        runtimeInputs = [ pkgs.s6 ];
      } ''
      deadline=$(expr $(date +%s) + ${toString spinupGrace})
      services=$@
      echo started feeding the dog
      exec 3> ''${WATCHDOG-/dev/watchdog}

      healthy(){
          test $(date +%s) -le $deadline && return 0

          for i in $services; do
              if test "$(s6-svstat -o up /run/service/$i)" != "true" ; then
                 echo "service $i is down"
                 return 1
              fi
          done
      }

      while healthy ;do
          sleep 10
          echo >&3
      done
      echo "stopped feeding the dog"
      sleep 6000  # don't want s6-rc to restart
    '';
    in longrun {
      name = "watchdog";
      run =
        "${script} ${lib.concatStringsSep " " (builtins.map (s: s.name) watched)}";
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

  services.defaultroute4 = svc.network.route.build {
    via = "$(output ${services.dhcpc} router)";
    target = "default";
    dependencies = [services.dhcpc];
  };

  programs.busybox  = {
    applets = ["blkid" "lsusb" "findfs" "tar"];
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
    up = ''
      while ! findfs LABEL=backup-disk; do
        echo waiting for backup-disk
        sleep 1
      done
      mount -t ext4 LABEL=backup-disk /srv
    '';
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
        uid = backup
        [srv]
          path = /srv
          use chroot = yes
          auth users = backup
          read only = false
          gid = backup
          secrets file = ${secrets_file}/.outputs/secrets
      '';
    in longrun {
      name = "rsync";
      run = ''
        ${pkgs.rsyncSmall}/bin/rsync --no-detach --daemon  --config=${configFile}
      '';
      dependencies = [
        secrets_file
        services.mount_external_disk
        config.hardware.networkInterfaces.lan
      ] ;
    };

  users.root = {
    passwd = lib.mkForce secrets.root_password;
    # openssh.authorizedKeys.keys = [
    #   (builtins.readFile "/home/dan/.ssh/id_rsa.pub")
    # ];
  };

  users.backup = {
    uid=500; gid=500; gecos="Storage owner"; dir="/srv";
    shell="/dev/null";
  };
  groups.backup = {
    gid=500; usernames = ["backup"];
  };

  defaultProfile.packages = with pkgs; [e2fsprogs strace tcpdump ];
}
