# This is not part of Liminix per se. This is my "scratchpad"
# configuration for the device I'm testing with.
#
# Parts of it do do things that Liminix eventually needs to do, but
# don't look in here for solutions - just for identifying the
# problems.


{ config, pkgs, lib, ... } :
let
  secrets = import ./rotuer-secrets.nix;
  inherit (pkgs.liminix.services) oneshot longrun;
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
    ../modules/standard.nix
    ../modules/network
    ../modules/ppp
    ../modules/dnsmasq
    ../modules/firewall
    ../modules/hostapd
    ../modules/bridge
    ../modules/ntp
    ../modules/ssh
  ];
  rootfsType = "jffs2";
  hostname = "rotuer";

  services.hostap = svc.hostapd.build {
    interface = config.hardware.networkInterfaces.wlan_24;
    params = {
      ssid = "liminix";
      hw_mode="g";
      channel = "2";
      ieee80211n = 1;
    } // wirelessConfig;
  };

  services.hostap5 = svc.hostapd.build {
    interface = config.hardware.networkInterfaces.wlan_5;
    params = rec {
      ssid = "liminix_5";
      hw_mode="a";
      channel = 36;
      ht_capab = "[HT40+]";
      vht_oper_chwidth = 1;
      vht_oper_centr_freq_seg0_idx = channel + 6;
      ieee80211ac = 1;
    } // wirelessConfig;
  };

  services.int = svc.network.address.build {
    interface = svc.bridge.primary.build { ifname = "int"; };
    family = "inet"; address ="10.8.0.1"; prefixLength = 16;
  };

  services.bridge =  svc.bridge.members.build {
    primary = services.int;
    members = with config.hardware.networkInterfaces;
      [ wlan_24 wlan_5 lan ];
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
        "10.8.0.10,10.8.0.240"
        "::,constructor:$(output ${interface} ifname),ra-stateless"
      ];
      domain = "fake.liminix.org";
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
    down = ''
      rm -rf /run/service-state/${name}/
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
    ruleset = import ./rotuer-firewall.nix;
  };

  services.packet_forwarding = svc.network.forward.build { };

  services.dhcp6 =
    let
      name = "dhcp6c.wan";
    in longrun {
      inherit name;
      notification-fd = 10;
      run = ''
        export SERVICE_STATE=/run/service-state/${name}
        ${pkgs.odhcp6c}/bin/odhcp6c -s ${pkgs.odhcp-script} -e -v -p /run/${name}.pid -P 48 $(output ${services.wan} ifname)
        )
      '';
      dependencies = [ services.wan ];
    };

  services.acquire-lan-prefix =
    let script = pkgs.callPackage ./acquire-delegated-prefix.nix {  };
    in longrun {
      name = "acquire-lan-prefix";
      run = "${script} /run/service-state/dhcp6c.wan $(output ${services.int} ifname)";
      dependencies = [ services.dhcp6 ];
    };

  services.acquire-wan-address =
    let script = pkgs.callPackage ./acquire-wan-address.nix {  };
    in longrun {
      name = "acquire-wan-address";
      run = "${script} /run/service-state/dhcp6c.wan $(output ${services.wan} ifname)";
      dependencies = [ services.dhcp6 ];
    };

  defaultProfile.packages = with pkgs; [
    min-collect-garbage
  ];
}
