# This is not part of Liminix per se. This is my "scratchpad"
# configuration for the device I'm testing with.
#
# Parts of it do do things that Liminix eventually needs to do, but
# don't look in here for solutions - just for identifying the
# problems.


{ config, pkgs, lib, ... } :
let
  secrets = import ./rotuer-secrets.nix;
  inherit (pkgs.liminix.networking)
    address
    bridge
    dnsmasq
    hostapd
    interface
    pppoe
    route;
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit (pkgs)
    ifwait
    serviceFns
    iptables;
in rec {
  services.loopback =
    let iface = interface { type = "loopback"; device = "lo";};
    in bundle {
      name = "loopback";
      contents = [
        (address iface { family = "inet4"; address ="127.0.0.1"; prefixLength = 8;})
        (address iface { family = "inet6"; address ="::1"; prefixLength = 128;})
      ];
    };

  boot = {
    tftp = {
      enable = true;
      serverip = "10.0.0.1";
      ipaddr = "10.0.0.8";
    };
  };

  imports = [
    ./modules/wlan.nix
    ./modules/phram.nix
  ];

  kernel = {
    config = {
      PPP = "y";
      PPP_BSDCOMP = "y";
      PPP_DEFLATE = "y";
      PPP_ASYNC = "y";
      PPP_SYNC_TTY = "y";
      BRIDGE = "y";

      NETFILTER_XT_MATCH_CONNTRACK = "y";

      IP6_NF_IPTABLES= "y";
      IP_NF_IPTABLES= "y";
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
      NF_NAT_MASQUERADE  = "y";
      NF_TABLES= "y";
      NF_TABLES_INET = "y";
      NF_TABLES_IPV4 = "y";
      NF_TABLES_IPV6 = "y";
    };
  };

  services.lan =
    let iface = interface {
          type = "bridge";
          device = "lan";
        };
    in address iface {
      family = "inet4"; address ="10.8.0.1"; prefixLength = 16;
    };

  services.wireless = interface {
    type = "hardware";
    device = "wlan0";
    dependencies = [ config.services.wlan_module ];
  };

  services.wired = interface {
    type = "hardware";
    device = "eth0";
    primary = services.lan;
  };

  services.hostap = hostapd (services.wireless) {
    params = {
      ssid = "liminix";
      country_code = "GB";
      hw_mode="g";
      channel = "2";
      wmm_enabled = 1;
      ieee80211n = 1;
      inherit (secrets) wpa_passphrase;
      auth_algs = 1; # 1=wpa2, 2=wep, 3=both
      wpa = 2;       # 1=wpa, 2=wpa2, 3=both
      wpa_key_mgmt = "WPA-PSK";
      wpa_pairwise = "TKIP CCMP";   # auth for wpa (may not need this?)
      rsn_pairwise = "CCMP";        # auth for wpa2
    };
  };

  services.bridgewlan =
    let dev = services.wireless.device;
    in oneshot {
      name = "add-wlan2-to-bridge";
      up = "${ifwait}/bin/ifwait -v ${dev} running && ip link set dev ${dev} master ${services.lan.device}";
      down = "ip link set dev ${dev} nomaster";
      dependencies = [ services.wireless ];
    };
    };

  users.dnsmasq = {
    uid = 51; gid= 51; gecos = "DNS/DHCP service user";
    dir = "/run/dnsmasq";
    shell = "/bin/false";
  };
  groups.dnsmasq = {
    gid = 51; usernames = ["dnsmasq"];
  };
  groups.system.usernames = ["dnsmasq"];

  services.dns =
    dnsmasq {
      resolvconf = services.resolvconf;
      interface = services.lan;
      ranges = ["10.8.0.10,10.8.0.240"];
      domain = "fake.liminix.org";
    };

  services.wan =
    let iface = interface { type = "hardware"; device = "eth1"; };
    in pppoe iface {
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
      ( cd `mkoutputs ${name}`; umask 0027
       echo "nameserver $(output ${services.wan} ns1)" > resolv.conf
       echo "nameserver $(output ${services.wan} ns2)" >> resolv.conf
      )
    '';
    down = ''
      rm -rf /run/service-state/${name}/
    '';
  };

  services.defaultroute4 = route {
    name = "defaultroute";
    via = "$(output ${services.wan} address)";
    target = "default";
    dependencies = [ services.wan ];
  };

  services.packet_forwarding =
    let filename = "/proc/sys/net/ipv4/conf/all/forwarding";
    in oneshot {
      name = "let-the-ip-flow";
      up = ''
        ${pkgs.nftables}/bin/nft -f ${./nat.nft}
        echo 1 > ${filename}
      '';
      down = "echo 0 > ${filename}";
    };

  services.default = target {
    name = "default";
    contents = with services; [
      loopback
      wired
      wireless
      lan
      hostap
      defaultroute4
      packet_forwarding
      dns
      bridgewlan
      resolvconf
    ];
  };
  defaultProfile.packages = with pkgs;  [ nftables strace tcpdump ] ;
}
