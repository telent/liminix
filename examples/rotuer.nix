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
    firewallRules = {};
  } // (import ./rotuer-secrets.nix);
  inherit (pkgs.liminix.services) oneshot bundle;
  inherit (pkgs) serviceFns;
  svc = config.system.service;
  wirelessConfig =  {
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
      address = {
        family = "inet"; address ="${secrets.lan.prefix}.1"; prefixLength = 24;
      };
    };
    wan = {
      interface = config.hardware.networkInterfaces.wan;
      username = secrets.l2tp.name;
      password = secrets.l2tp.password;
      dhcp6.enable = true;
    };

    wireless.networks = {
      telent = {
        interface = config.hardware.networkInterfaces.wlan;
        ssid = secrets.ssid;
        hw_mode="g";
        channel = "2";
        ieee80211n = 1;
      } // wirelessConfig;
      telent5 = rec {
        interface = config.hardware.networkInterfaces.wlan5;
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
  };

  services.ntp = svc.ntp.build {
    pools = { "pool.ntp.org" = ["iburst"]; };
    makestep = { threshold = 1.0; limit = 3; };
  };

  services.sshd = svc.ssh.build { };

  users.root = secrets.root;

  services.dns =
    let interface = config.services.int;
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

  services.resolvconf = oneshot rec {
    dependencies = [ config.services.wan ];
    name = "resolvconf";
    up = ''
      . ${serviceFns}
      ( in_outputs ${name}
       echo "nameserver $(output ${config.services.wan} ns1)" > resolv.conf
       echo "nameserver $(output ${config.services.wan} ns2)" >> resolv.conf
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
    via = "$(output ${config.services.wan} address)";
    target = "default";
    dependencies = [ config.services.wan ];
  };

  services.defaultroute6 = svc.network.route.build {
    via = "$(output ${config.services.wan} ipv6-peer-address)";
    target = "default";
    interface = config.services.wan;
  };

  services.firewall = svc.firewall.build {
    ruleset =
      let defaults = import ./demo-firewall.nix;
      in lib.recursiveUpdate defaults secrets.firewallRules;
  };

  services.packet_forwarding = svc.network.forward.build { };

  services.dhcp6c =
    let client = svc.dhcp6c.client.build {
          interface = config.services.wan;
        };
    in bundle {
      name = "dhcp6c";
      contents = [
        (svc.dhcp6c.prefix.build {
          inherit client;
          interface = config.services.int;
        })
        (svc.dhcp6c.address.build {
          inherit client;
          interface = config.services.wan;
        })
      ];
    };

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
