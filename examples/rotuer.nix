# This is not part of Liminix per se. This is my "scratchpad"
# configuration for the device I'm testing with.
#
# Parts of it do do things that Liminix eventually needs to do, but
# don't look in here for solutions - just for identifying the
# problems.


{ config, pkgs, lib, modulesPath, ... } :
let
  secrets = {
    domainName = "fake.liminix.org";
    firewallRules = { };
  } // (import ./rotuer-secrets.nix);
  svc = config.system.service;
  wirelessConfig = {
    country_code = "GB";
    inherit (secrets) wpa_passphrase;
    wmm_enabled = 1;
  };

in rec {
  boot = {
    tftp = {
      freeSpaceBytes = 3 * 1024 * 1024;
      serverip = "10.0.0.1";
      ipaddr = "10.0.0.8";
    };
  };

  imports = [
    "${modulesPath}/profiles/gateway.nix"
    "${modulesPath}/schnapps"
    "${modulesPath}/outputs/btrfs.nix"
    "${modulesPath}/outputs/extlinux.nix"
  ];
  hostname = "rotuer";
  rootfsType = "btrfs";
  rootOptions = "subvol=@";
  boot.loader.extlinux.enable = true;

  profile.gateway = {
    lan = {
      interfaces =  with config.hardware.networkInterfaces;
        [
          wlan wlan5
          lan0 lan1 lan2 lan3 lan4
        ];
      inherit (secrets.lan) prefix;
      address = {
        family = "inet"; address ="${secrets.lan.prefix}.1"; prefixLength = 24;
      };
      dhcp = {
        start = 10;
        end = 240;
        hosts = { } // lib.optionalAttrs (builtins.pathExists ./static-leases.nix) (import ./static-leases.nix);
        localDomain = "lan";
      };
    };
    wan = {
      interface = config.hardware.networkInterfaces.wan;
      username = secrets.l2tp.name;
      password = secrets.l2tp.password;
      dhcp6.enable = true;
    };
    firewall = {
      enable = true;
      rules = secrets.firewallRules;
    };
    wireless.networks = {
      "${secrets.ssid}" = {
        interface = config.hardware.networkInterfaces.wlan;
        hw_mode = "g";
        channel = "2";
        ieee80211n = 1;
      } // wirelessConfig;
      "${secrets.ssid}5" = rec {
        interface = config.hardware.networkInterfaces.wlan5;
        hw_mode = "a";
        channel = 36;
        ht_capab = "[HT40+]";
        vht_oper_chwidth = 1;
        vht_oper_centr_freq_seg0_idx = channel + 6;
        ieee80211n = 1;
        ieee80211ac = 1;
      } // wirelessConfig;
    };
  };

  services.ntp = svc.ntp.build {
    pools = { "pool.ntp.org" = ["iburst"]; };
    makestep = { threshold = 1.0; limit = 3; };
  };

  services.sshd = svc.ssh.build { };

  users.root = secrets.root;

  defaultProfile.packages = with pkgs; [
    min-collect-garbage
    nftables
    strace
    tcpdump
    s6
  ];

  programs.busybox = {
    applets = [
      "fdisk" "sfdisk"
    ];
    options = {
      FEATURE_FANCY_TAIL = "y";
    };
  };
}
