{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = import ./extneder-secrets.nix;
  rsecrets = import ./rotuer-secrets.nix;

  # https://support.aa.net.uk/Category:Incoming_L2TP says:
  # "Please use the DNS name (l2tp.aa.net.uk) instead of hardcoding an
  # IP address; IP addresses can and do change. If you have to use an
  # IP, use 194.4.172.12, but do check the DNS for l2tp.aa.net.uk in
  # case it changes."

  # but (1) we don't want to use the wwan stick's dns as our main
  # resolver: it's provided by some mobile ISP and they aren't
  # necessarily the best at providing unfettered services without
  # deciding to do something weird; (2) it's not simple to arrange
  # that xl2tpd gets a different resolver than every other process;
  # (3) there's no way to specify an lns address to xl2tpd at runtime
  # except by rewriting its config file. So what we will do is lookup
  # the lns hostname using the mobile ISP's dns server and then refuse
  # to start l2tp unless the expected lns address is one of the
  # addresses returned. I think this satisfies "do check the DNS"

  lns = { hostname = "l2tp.aaisp.net.uk"; address = "194.4.172.12"; };

  inherit (pkgs.liminix.services) oneshot longrun target;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) serviceFns;
  svc = config.system.service;
  wirelessConfig = {
    country_code = "GB";
    inherit (rsecrets) wpa_passphrase;
    wmm_enabled = 1;
  };
in rec {
  boot = {
    tftp = {
      serverip = "10.0.0.1";
      ipaddr = "10.0.0.8";
    };
  };

  imports = [
    ../modules/wwan
    ../modules/network
    # ../modules/vlan
    ../modules/ssh
    ../modules/usb.nix
    # ../modules/watchdog
    # ../modules/mount
    ../modules/ppp
    ../modules/round-robin
    ../modules/profiles/gateway.nix
  ];
  hostname = "thing";

  services.wwan = svc.wwan.huawei-e3372.build {
    apn = "data.uk";
    username = "user";
    password = "one2one";
    authType = "chap";
  };

  profile.gateway = {
    lan = {
      interfaces =  with config.hardware.networkInterfaces;
        [
          # EDIT: these are the interfaces exposed by the gl.inet gl-ar750:
          # if your device has more or differently named lan interfaces,
          # specify them here
          wlan wlan5
          lan
        ];
      inherit (rsecrets.lan) prefix;
      address = {
        family = "inet"; address ="${rsecrets.lan.prefix}.1"; prefixLength = 24;
      };
      dhcp = {
        start = 10;
        end = 240;
        hosts = { } // lib.optionalAttrs (builtins.pathExists ./static-leases.nix) (import ./static-leases.nix);
        localDomain = "lan";
      };
    };
    wan = {
      interface = let
        pppoe = svc.pppoe.build {
          interface = config.hardware.networkInterfaces.wan;
          debug = true;
          username = rsecrets.l2tp.name;
          password = rsecrets.l2tp.password;
        };

        l2tp =
          let
            check-address = oneshot rec {
              name = "check-lns-address";
              up = "grep -Fx ${lns.address} $(output_path ${services.lns-address} addresses)";
              dependencies = [ services.lns-address ];
            };
            route = svc.network.route.build {
              via = "$(output ${services.bootstrap-dhcpc} router)";
              target = lns.address;
              dependencies = [services.bootstrap-dhcpc check-address];
            };
          in svc.l2tp.build {
            lns = lns.address;
            ppp-options = [
              "debug" "+ipv6" "noauth"
              "name" rsecrets.l2tp.name
              "password" rsecrets.l2tp.password
            ];
            dependencies = [config.services.lns-address route check-address];
          };
      in svc.round-robin.build {
        name = "wan";
        services = [ l2tp pppoe ];
      };
      dhcp6.enable = true;
    };

    wireless.networks = {
      "${rsecrets.ssid}" = {
        interface = config.hardware.networkInterfaces.wlan;
        hw_mode = "g";
        channel = "6";
        ieee80211n = 1;
      } // wirelessConfig;
      "${rsecrets.ssid}5" = rec {
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

  services.bootstrap-dhcpc = svc.network.dhcp.client.build {
    interface = config.services.wwan;
    dependencies = [ config.services.hostname ];
  };

  services.sshd = svc.ssh.build { };

  services.lns-address = let
    ns = "$(output_word ${services.bootstrap-dhcpc} dns 1)";
    route-to-bootstrap-nameserver = svc.network.route.build {
      via = "$(output ${services.bootstrap-dhcpc} router)";
      target = ns;
      dependencies = [services.bootstrap-dhcpc];
    };
  in oneshot rec {
    name = "resolve-l2tp-server";
    dependencies = [ services.bootstrap-dhcpc route-to-bootstrap-nameserver ];
    up = ''
      (in_outputs ${name}
       DNSCACHEIP="${ns}" ${pkgs.s6-dns}/bin/s6-dnsip4 ${lns.hostname} \
        > addresses
      )
    '';
  };

  # services.ntp = svc.ntp.build {
  #   pools = { "pool.ntp.org" = ["iburst"]; };
  #   makestep = { threshold = 1.0; limit = 3; };
  #   dependencies = with config.services; [ defaultroute4 defaultroute6 ];
  # };

  users.root = rsecrets.root;

  programs.busybox.options = {
    FEATURE_FANCY_TAIL = "y";
  };

}
