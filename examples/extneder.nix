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
    interface
    route
  ;
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) dropbear ifwait serviceFns;
  svc = config.system.service;
in rec {
  boot = {
    tftp = {
      serverip = "192.168.8.148";
      ipaddr = "192.168.8.251";
    };
  };

  imports = [
    ../modules/wlan.nix
    ../modules/network
    ../modules/hostapd
    ../modules/bridge
    ../modules/standard.nix
  ];

  hostname = "extneder";

  kernel = {
    config = {

      NETFILTER_XT_MATCH_CONNTRACK = "y";

      IP6_NF_IPTABLES = "y"; # do we still need these
      IP_NF_IPTABLES = "y"; # if using nftables directly

      # these are copied from rotuer and need review
      IP_NF_NAT = "y";
      IP_NF_TARGET_MASQUERADE = "y";
      NETFILTER = "y";
      NETFILTER_ADVANCED = "y";
      NETFILTER_XTABLES = "y";

      NFT_COMPAT = "y";
      NFT_CT = "y";
      NFT_LOG = "y";
      NFT_MASQ = "y";
      NFT_NAT = "y";
      NFT_REJECT = "y";
      NFT_REJECT_INET = "y";

      NF_CONNTRACK = "y";
      NF_NAT = "y";
      NF_NAT_MASQUERADE = "y";
      NF_TABLES = "y";
      NF_TABLES_INET = "y";
      NF_TABLES_IPV4 = "y";
      NF_TABLES_IPV6 = "y";
    };
  };

  services.hostap = svc.hostapd.build {
    interface = config.hardware.networkInterfaces.wlan;
    params = {
      country_code = "GB";
      hw_mode = "g";
      wmm_enabled = 1;
      ieee80211n = 1;
      inherit (secrets) ssid channel wpa_passphrase;
      auth_algs = 1; # 1=wpa2, 2=wep, 3=both
      wpa = 2; # 1=wpa, 2=wpa2, 3=both
      wpa_key_mgmt = "WPA-PSK";
      wpa_pairwise = "TKIP CCMP"; # auth for wpa (may not need this?)
      rsn_pairwise = "CCMP"; # auth for wpa2
    };
  };

  services.int = interface {
    type = "bridge";
    device = "int";
  };

  services.dhcpc = svc.network.dhcp.client.build {
    interface = services.int;
    dependencies = [ config.services.hostname ];
  };

  services.bridge = svc.bridge.members.build {
    primary = services.int;
    members = with config.hardware.networkInterfaces; [
      lan
      wlan
    ];
  };

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
    # CHECK: https://udhcp.busybox.net/README.udhcpc says
    # 'A list of DNS server' but doesn't say what separates the
    # list members. Assuming it's a space or other IFS character
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
  };

  services.defaultroute4 = route {
    name = "defaultroute";
    via = "$(output ${services.dhcpc} router)";
    target = "default";
    dependencies = [services.dhcpc];
  };

  services.default = target {
    name = "default";
    contents =
      let links = config.hardware.networkInterfaces;
      in with config.services; [
        links.lo links.eth links.wlan
        int
        bridge
        hostap
        defaultroute4
        resolvconf
        sshd
      ];
  };
  users.root.passwd = lib.mkForce secrets.root_password;
  defaultProfile.packages = with pkgs; [nftables strace tcpdump swconfig];
}
