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

  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) writeText dropbear ifwait serviceFns;
  svc = config.system.service;
in rec {
  boot = {
    tftp = {
      serverip = "10.0.0.1";
      ipaddr = "10.0.0.8";
    };
  };

  imports = [
    ../modules/cdc-ncm
    ../modules/network
    ../modules/vlan
    ../modules/ssh
    ../modules/usb.nix
    ../modules/watchdog
    ../modules/mount
    ../modules/ppp
  ];
  hostname = "thing";

  services.wwan = svc.wwan.build {
    apn = "data.uk";
    username = "user";
    password = "one2one";
    authType = "chap";
  };

  services.dhcpc = svc.network.dhcp.client.build {
    interface = config.services.wwan;
    dependencies = [ config.services.hostname ];
  };

  services.sshd = svc.ssh.build { };

  services.resolvconf = oneshot rec {
    dependencies = [ services.l2tp ];
    name = "resolvconf";
    up = ''
      . ${serviceFns}
       ( in_outputs ${name}
        for i in ns1 ns2 ; do
          ns=$(output ${services.l2tp} $i)
          echo "nameserver $ns" >> resolv.conf
        done
       )
    '';
  };
  filesystem = dir {
    etc = dir {
      "resolv.conf" = symlink "${services.resolvconf}/.outputs/resolv.conf";
    };
  };

  services.lns-address = let
    ns = "$(output_word ${services.dhcpc} dns 1)";
    route-to-bootstrap-nameserver = svc.network.route.build {
      via = "$(output ${services.dhcpc} router)";
      target = ns;
      dependencies = [services.dhcpc];
    };
  in oneshot rec {
    name = "resolve-l2tp-server";
    dependencies = [ services.dhcpc route-to-bootstrap-nameserver ];
    up = ''
      (in_outputs ${name}
       DNSCACHEIP="${ns}" ${pkgs.s6-dns}/bin/s6-dnsip4 ${lns.hostname} \
        > addresses
      )
    '';
  };

  services.l2tp =
    let
      check-address = oneshot rec {
        name = "check-lns-address";
        up = ''
          grep -Fx ${lns.address} $(output_path ${services.lns-address} addresses)
        '';
        dependencies = [ services.lns-address ];
      };
      route = svc.network.route.build {
        via = "$(output ${services.dhcpc} router)";
        target = lns.address;
        dependencies = [services.dhcpc check-address];
      };
    in svc.l2tp.build {
      lns = lns.address;
      ppp-options = [
        "debug" "+ipv6" "noauth"
        "name" rsecrets.l2tp.name
        "connect-delay" "5000"
        "password" rsecrets.l2tp.password
      ];
      dependencies = [config.services.lns-address route check-address];
  };

  services.defaultroute4 = svc.network.route.build {
    via = "$(output ${services.l2tp} peer-address)";
    target = "default";
    dependencies = [services.l2tp];
  };

#  defaultProfile.packages = [ pkgs.go-l2tp ];

  users.root = {
    passwd = lib.mkForce secrets.root.passwd;
    openssh.authorizedKeys.keys = secrets.root.keys;
  };
}
