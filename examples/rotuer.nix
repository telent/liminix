# This is not part of Liminix per se. This is my "scratchpad"
# configuration for the device I'm testing with.
#
# Parts of it do do things that Liminix eventually needs to do, but
# don't look in here for solutions - just for identifying the
# problems.


{ config, pkgs, lib, ... } :
let
  secrets = {
    domainName = "fake.liminix.org";
    firewallRules = {};
  } // (import ./rotuer-secrets.nix);
  inherit (pkgs.liminix.services) oneshot longrun bundle;
  inherit (pkgs) serviceFns;
  svc = config.system.service;
  wirelessConfig =  {
    country_code = "GB";
    inherit (secrets) wpa_passphrase;
    auth_algs = 1; # 1=wpa2, 2=wep, 3=both
    wpa = 2;       # 1=wpa, 2=wpa2, 3=both
    wpa_key_mgmt = "WPA-PSK";
    wpa_pairwise = "TKIP CCMP";   # auth for wpa (may not need this?)
    rsn_pairwise = "CCMP";        # auth for wpa2
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
    ../modules/wlan.nix
    ../modules/network
    ../modules/ppp
    ../modules/dnsmasq
    ../modules/dhcp6c
    ../modules/firewall
    ../modules/hostapd
    ../modules/bridge
    ../modules/ntp
    ../modules/schnapps
    ../modules/ssh
    ../modules/outputs/btrfs.nix
    ../modules/outputs/extlinux.nix
  ];
  hostname = "rotuer";
  rootfsType = "btrfs";
  rootOptions = "subvol=@";
  boot.loader.extlinux.enable = true;

  services.hostap = svc.hostapd.build {
    interface = config.hardware.networkInterfaces.wlan;
    params = {
      ssid = secrets.ssid;
      hw_mode="g";
      channel = "2";
      ieee80211n = 1;
    } // wirelessConfig;
  };

  services.hostap5 = svc.hostapd.build {
    interface = config.hardware.networkInterfaces.wlan5;
    params = rec {
      ssid = "${secrets.ssid}5";
      hw_mode="a";
      channel = 36;
      ht_capab = "[HT40+]";
      vht_oper_chwidth = 1;
      vht_oper_centr_freq_seg0_idx = channel + 6;
      ieee80211n = 1;
      ieee80211ac = 1;
    } // wirelessConfig;
  };

  services.int = svc.network.address.build {
    interface = svc.bridge.primary.build { ifname = "int"; };
    family = "inet"; address ="${secrets.lan.prefix}.1"; prefixLength = 24;
  };

  services.bridge =  svc.bridge.members.build {
    primary = services.int;
    members = with config.hardware.networkInterfaces;
      [
        wlan
        wlan5
        lan0
        lan1
        lan2
        lan3
        lan4
      ];
  };

  services.ntp = svc.ntp.build {
    pools = { "pool.ntp.org" = ["iburst"]; };
    makestep = { threshold = 1.0; limit = 3; };
  };

  services.sshd = svc.ssh.build { };

  users.root = secrets.root;

  services.dns =
    let interface = services.int;
    in svc.dnsmasq.build {
      resolvconf = services.resolvconf;
      inherit interface;
      ranges = [
        "${secrets.lan.prefix}.10,${secrets.lan.prefix}.240"
        # ra-stateless: sends router advertisements with the O and A
        # bits set, and provides a stateless DHCP service. The client
        # will use a SLAAC address, and use DHCP for other
        # configuration information.
        "::,constructor:$(output ${interface} ifname),ra-stateless"
      ];

      # You can add static addresses for the DHCP server here.  I'm
      # not putting my actual MAC addresses in a public git repo ...
      hosts = { } // lib.optionalAttrs (builtins.pathExists ./static-leases.nix) (import ./static-leases.nix);
      upstreams = [ "/${secrets.domainName}/" ];
      domain = secrets.domainName;
    };

  services.wan = svc.pppoe.build {
    interface = config.hardware.networkInterfaces.wan;
    ppp-options = [
      "debug" "+ipv6" "noauth"
      "name" secrets.l2tp.name
      "password" secrets.l2tp.password
    ];
  };

  services.resolvconf = oneshot rec {
    dependencies = [ services.wan ];
    name = "resolvconf";
    up = ''
      . ${serviceFns}
      ( in_outputs ${name}
       echo "nameserver $(output ${services.wan} ns1)" > resolv.conf
       echo "nameserver $(output ${services.wan} ns2)" >> resolv.conf
       chmod 0444 resolv.conf
      )
    '';
  };

  filesystem =
    let inherit (pkgs.pseudofile) dir symlink;
    in dir {
      etc = dir {
        "resolv.conf" = symlink "${services.resolvconf}/.outputs/resolv.conf";
      };
    };

  services.defaultroute4 = svc.network.route.build {
    via = "$(output ${services.wan} address)";
    target = "default";
    dependencies = [ services.wan ];
  };

  services.defaultroute6 = svc.network.route.build {
    via = "$(output ${services.wan} ipv6-peer-address)";
    target = "default";
    interface = services.wan;
  };

  services.firewall = svc.firewall.build {
    ruleset =
      let defaults = import ./demo-firewall.nix;
      in lib.recursiveUpdate defaults secrets.firewallRules;
  };

  services.packet_forwarding = svc.network.forward.build { };

  services.dhcp6c =
    let client = svc.dhcp6c.client.build {
          interface = services.wan;
        };
    in bundle {
      name = "dhcp6c";
      contents = [
        (svc.dhcp6c.prefix.build {
          inherit client;
          interface = services.int;
        })
        (svc.dhcp6c.address.build {
          inherit client;
          interface = services.wan;
        })
      ];
    };

  defaultProfile.packages = with pkgs; [
    min-collect-garbage
  ];

  programs.busybox.applets = [
    "fdisk" "sfdisk"
  ];
}
