# This is an example that uses the "gateway" profile to create a
# "typical home wireless router" configuration suitable for a Gl.inet
# gl-ar750 router. It should be fairly simple to edit it for other
# devices: mostly you will need to attend to the number of wlan and lan
# interfaces

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
  inherit (pkgs.liminix.services) longrun;
in rec {
  boot = {
    tftp = {
      freeSpaceBytes = 2 * 1024 * 1024;
      serverip = "10.0.0.1";
      ipaddr = "10.0.0.8";
    };
  };

  imports = [
    "${modulesPath}/profiles/gateway.nix"
    "${modulesPath}/tls-certificate"
  ];

  hostname = "rotuer";
#  rootfsType = "jffs2";

  filesystem =
    let inherit (pkgs.pseudofile) file dir symlink;
    in dir {
      mnt = dir {};
      etc = dir {
        hosts = {
          type = "f";
          file = "127.0.0.1 localhost\n10.0.0.1 loaclhost.telent.net\n";
          mode = "0444";
        };
      };
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
      # wan interface depends on your upstream - could be dhcp, static
      # ethernet, a pppoe, ppp over serial, a complicated bonded
      # failover ... who knows what else?
      interface = svc.pppoe.build {
        interface = config.hardware.networkInterfaces.wan;
        username = secrets.l2tp.name;
        password = secrets.l2tp.password;
      };
      # once the wan has ipv4 connnectivity, should we run dhcp6
      # client to potentially get an address range ("prefix
      # delegation")
      dhcp6.enable = true;
    };
    firewall = {
      enable = true;
      rules = secrets.firewallRules;
    };
    wireless.networks = {
      # EDIT: if you have more or fewer wireless radios, here is where
      # you need to say so.  hostapd tuning is hardware-specific and
      # left as an exercise for the reader :-).

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
    # strace
    # tcpdump
    s6
    dtc
    # certifix-client
  ];

  programs.busybox = {
    applets = [
      "fdisk" "sfdisk"
    ];
    options = {
      FEATURE_FANCY_TAIL = "y";
    };
  };

  services.wan-address-for-secrets =
    let
      interface = config.hardware.networkInterfaces.wan;
      addr =
        svc.network.address.build {
          inherit interface;
          family = "inet"; address ="10.0.0.10"; prefixLength = 24;
        };
    in svc.network.route.build {
      target = "10.0.0.1";
      inherit interface;
      via = "10.0.0.10";
      metric = 1;
      dependencies = [ addr ];
    };

  # services.client-cert = svc.tls-certificate.certifix-client.build {
  #   caCertificate = builtins.readFile /var/lib/certifix/certs/ca.crt;
  #   subject = "C=GB,ST=London,O=Telent,OU=devices,CN=${config.hostname}";
  #   secret = builtins.readFile ../challengePassword;
  #   serviceUrl = "https://loaclhost.telent.net:19613/sign";
  #   dependencies = [ services.wan-address-for-secrets ];
  # };

  logging.pstore = true;
  logging.shipping = {
    enable = false;
    service = longrun {
      name = "ship-logs";
      dependencies = [ config.services.client-cert ];
      run =
        let path = lib.makeBinPath (with pkgs; [ s6-networking s6 ]);
        in ''
          PATH=${path}:$PATH \
          CAFILE=${/var/lib/certifix/certs/ca.crt} \
          KEYFILE=$(output_path ${services.client-cert} key) \
          CERTFILE=$(output_path ${services.client-cert} cert) \
          s6-tlsclient -k loaclhost.telent.net -h -y loaclhost.telent.net 19612 \
          fdmove -c 1 7 cat
        '';
    };
  };
}
