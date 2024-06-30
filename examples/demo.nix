# This is an example configuration for a "typical" small office/home
# router and wifi access point.

# You need to copy it to another filename and change the configuration
# wherever the text "EDIT" appears - please consult the tutorial
# documentation for details.

{ config, pkgs, ... }:
let
  inherit (pkgs.liminix.services) bundle oneshot;
  inherit (pkgs) serviceFns;
  # EDIT: you can pick your preferred RFC1918 address space
  # for NATted connections, if you don't like this one.
  ipv4LocalNet = "10.8.0";
  svc = config.system.service;

in rec {
  boot = {
    tftp = {
      freeSpaceBytes = 3 * 1024 * 1024;
      serverip = "10.0.0.1";
      ipaddr = "10.0.0.8";
    };
  };

  imports = [
    ../modules/bridge
    ../modules/dhcp6c
    ../modules/dnsmasq
    ../modules/firewall
    ../modules/hostapd
    ../modules/network
    ../modules/ntp
    ../modules/ppp
    ../modules/ssh
    ../modules/vlan
    ../modules/wlan.nix
  ];
  rootfsType = "jffs2";
  hostname = "the-internet"; # EDIT

  services.hostap = svc.hostapd.build {
    interface = config.hardware.networkInterfaces.wlan;
    # EDIT: you will want to change the obvious things
    # here to values of your choice
    params = {
      ssid = "the-internet";
      channel = "1";
      country_code = "GB";
      wpa_passphrase = "not a real wifi password";

      hw_mode = "g";
      ieee80211n = 1;
      auth_algs = 1; # 1=wpa2, 2=wep, 3=both
      wpa = 2; # 1=wpa, 2=wpa2, 3=both
      wpa_key_mgmt = "WPA-PSK";
      wpa_pairwise = "TKIP CCMP"; # auth for wpa (may not need this?)
      rsn_pairwise = "CCMP"; # auth for wpa2
      wmm_enabled = 1;
    };
  };

  services.int = svc.network.address.build {
    interface = svc.bridge.primary.build { ifname = "int"; };
    family = "inet";
    address = "${ipv4LocalNet}.1";
    prefixLength = 16;
  };

  services.bridge = svc.bridge.members.build {
    primary = services.int;
    members = with config.hardware.networkInterfaces; [
      wlan
      lan
    ];
  };

  services.ntp = svc.ntp.build {
    pools = {
      "pool.ntp.org" = [ "iburst" ];
    };
    makestep = {
      threshold = 1.0;
      limit = 3;
    };
  };

  services.sshd = svc.ssh.build { };

  users.root = {
    # EDIT: choose a root password and then use
    # "mkpasswd -m sha512crypt" to determine the hash.
    # It should start wirh $6$.
    passwd = "$6$6HG7WALLQQY1LQDE$428cnouMJ7wVmyK9.dF1uWs7t0z9ztgp3MHvN5bbeo0M4Kqg/u2ThjoSHIjCEJQlnVpDOaEKcOjXAlIClHWN21";
    openssh.authorizedKeys.keys = [
      # EDIT: you can add your ssh pubkey here
      # "ssh-rsa AAAAB3NzaC1....H6hKd user@example.com";
    ];
  };

  services.dns =
    let interface = services.int;
    in svc.dnsmasq.build {
      resolvconf = services.resolvconf;
      inherit interface;
      ranges = [
        "${ipv4LocalNet}.10,${ipv4LocalNet}.249"
        # EDIT: ... maybe. In this example we use "ra-stateless",
        # meaning dnsmasq sends router advertisements with the O and A
        # bits set, and provides a stateless DHCP service. The client
        # will use a SLAAC address, and use DHCP for other
        # configuration information.
        # If you didn't understand the preceding sentence then
        # the default is _probably_ fine, but if you need
        # a DHCP-only IPv6 network or some other different
        # configuration, this is the place to change it.
        "::,constructor:$(output ${interface} ifname),ra-stateless"
      ];
      # EDIT: choose a domain name for the DNS names issued for your
      # DHCP-issued hosts
      domain = "lan.example.com";
    };

  services.wan = svc.pppoe.build {
    interface = config.hardware.networkInterfaces.wan;
    ppp-options = [
      "debug" "+ipv6" "noauth"
      # EDIT: change the strings "chap-username"
      # and "chap-secret" to match the username/password
      # provided by your ISP for PPP logins
      "name" "chap-username"
      "password" "chap-secret"
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

  services.firewall = svc.firewall.build { };

  services.packet_forwarding = svc.network.forward.build { };

  # We expect the ISP uses DHCP6 to issue IPv6 addresses. There is a
  # service to request address information in the form of a DHCP
  # lease, and two dependent services that listen for updates to the
  # DHCP address information and update the addresses of the WAN and
  # LAN interfaces respectively.

  services.dhcp6c =
    let client = svc.dhcp6c.client.build {
          interface = services.wan;
        };
    in bundle {
      name = "dhcp6c";
      contents = [
        (svc.dhcp6c.prefix.build {
          # if your ISP provides you a real IPv6 prefix for your local
          # network (usually a /64 or /48 or something in between the
          # two), this service subscribes to that "prefix delegation"
          # information, and uses it to assign an address to the LAN
          # device. dnsmasq will notice this address and use it to
          # form the addresses it hands out to devices on the lan
          inherit client;
          interface = services.int;
        })
        (svc.dhcp6c.address.build {
          # if your ISP provides you a regular global IPv6 address,
          # this service subscribes to that information and assigns
          # the address to the WAN device.
          inherit client;
          interface = services.wan;
        })
      ];
    };

  defaultProfile.packages = with pkgs; [ min-collect-garbage ];
}
