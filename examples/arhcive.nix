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
  inherit (pkgs.liminix.services) oneshot longrun target;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) writeText serviceFns;
  svc = config.system.service;
in rec {
  boot = {
    tftp = {
      serverip = "10.0.0.1";
      ipaddr = "10.0.0.8";
    };
  };

  imports = [
    ../modules/wlan.nix
    ../modules/network
    ../modules/vlan
    ../modules/ssh
    ../modules/usb.nix
    ../modules/watchdog
    ../modules/mount
  ];
  hostname = "arhcive";


  services.dhcpc =
    let iface = config.hardware.networkInterfaces.lan;
    in svc.network.dhcp.client.build {
      interface = iface;
      dependencies = [ config.services.hostname ];
    };

  services.sshd = svc.ssh.build { };

  services.watchdog = svc.watchdog.build {
    watched = with config.services ; [ sshd dhcpc ];
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
    applets = ["lsusb" "tar"];
    options = {
      FEATURE_LS_TIMESTAMPS = "y";
      FEATURE_LS_SORTFILES = "y";
      FEATURE_VOLUMEID_EXT = "y";
    };
  };

  services.mount_external_disk = svc.mount.build {
    partlabel = "backup-disk";
    mountpoint = "/srv";
    fstype = "ext4";
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
      ];
    };

  users.root = {
    passwd = lib.mkForce secrets.root.passwd;
    openssh.authorizedKeys.keys = secrets.root.keys;
  };

  users.backup = {
    uid = 500;
    gid = 500;
    gecos = "Storage owner";
    dir = "/srv";
    shell = "/dev/null";
  };
  groups.backup = {
    gid = 500;
    usernames = [ "backup" ];
  };

  defaultProfile.packages = with pkgs; [
    e2fsprogs
    mtdutils
    (levitate.override {
      config = {
        services = {
          inherit (config.services) dhcpc sshd watchdog;
        };
        defaultProfile.packages = [ mtdutils ];
        users.root.openssh.authorizedKeys.keys = secrets.root.keys;
      };
    })
  ];
}
