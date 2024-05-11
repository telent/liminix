{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = import ./extneder-secrets.nix;
  rsecrets = import ./rotuer-secrets.nix;
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
#    ../modules/wlan.nix
    ../modules/network
    ../modules/vlan
    ../modules/ssh
    ../modules/usb.nix
    ../modules/watchdog
    ../modules/mount
    ../modules/ppp
  ];
  hostname = "thing";

  services.dhcpc =
    let iface = config.hardware.networkInterfaces.lan;
    in svc.network.dhcp.client.build {
      interface = iface;
      dependencies = [ config.services.hostname ];
    };

  services.sshd = svc.ssh.build { };

  services.resolvconf = oneshot rec {
    dependencies = [ services.dhcpc ];
    name = "resolvconf";
    up = ''
      . ${serviceFns}
      ( in_outputs ${name}
      for i in $(output ${services.dhcpc} dns); do
        echo "nameserver $i" > resolv.conf
      done
      )
    '';
  };
  filesystem = dir {
    etc = dir {
      "resolv.conf" = symlink "${services.resolvconf}/.outputs/resolv.conf";
    };
    srv = dir {};
  };

  services.l2tp = svc.l2tp.build {
    lns = "l2tp.aaisp.net.uk";
    ppp-options = [
      "debug" "+ipv6" "noauth"
      "name" rsecrets.l2tp.name
      "password" rsecrets.l2tp.password
    ];
    dependencies = [ services.defaultroute4 ];
  };

  services.defaultroute4 = svc.network.route.build {
    via = "$(output ${services.dhcpc} router)";
    target = "default";
    dependencies = [services.dhcpc];
  };

  users.root = {
    passwd = lib.mkForce secrets.root.passwd;
    openssh.authorizedKeys.keys = secrets.root.keys;
  };

  users.backup = {
    uid=500; gid=500; gecos="Storage owner"; dir="/srv";
    shell="/dev/null";
  };
  groups.backup = {
    gid=500; usernames = ["backup"];
  };

  defaultProfile.packages = with pkgs; [
    # e2fsprogs
    # mtdutils
    # (levitate.override {
    #   config  = {
    #     services = {
    #       inherit (config.services) dhcpc sshd watchdog;
    #     };
    #     defaultProfile.packages = [ mtdutils ];
    #     users.root.openssh.authorizedKeys.keys = secrets.root.keys;
    #   };
    # })
  ];
}
