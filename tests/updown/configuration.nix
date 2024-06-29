{ config, pkgs, ... } :
let
  # EDIT: you can pick your preferred RFC1918 address space
  # for NATted connections, if you don't like this one.
  ipv4LocalNet = "10.8.0";
  svc = config.system.service;

in rec {
  imports = [
    ../../modules/bridge
    ../../modules/dhcp6c
    ../../modules/dnsmasq
    ../../modules/firewall
    ../../modules/hostapd
    ../../modules/network
    ../../modules/ssh
    ../../modules/vlan
    ../../modules/wlan.nix
  ];
  rootfsType = "jffs2";
  hostname = "updown";

  services.int = svc.network.address.build {
    interface = svc.bridge.primary.build { ifname = "int"; };
    family = "inet"; address = "${ipv4LocalNet}.1"; prefixLength = 16;
  };

  services.bridge =  svc.bridge.members.build {
    primary = services.int;
    members = with config.hardware.networkInterfaces;
      [ lan ];
  };

  services.sshd = svc.ssh.build { };

  # users.root = {
  #   # EDIT: choose a root password and then use
  #   # "mkpasswd -m sha512crypt" to determine the hash.
  #   # It should start wirh $6$.
  #   passwd = "$6$6HG7WALLQQY1LQDE$428cnouMJ7wVmyK9.dF1uWs7t0z9ztgp3MHvN5bbeo0M4Kqg/u2ThjoSHIjCEJQlnVpDOaEKcOjXAlIClHWN21";
  #   openssh.authorizedKeys.keys = [
  #     # EDIT: you can add your ssh pubkey here
  #     # "ssh-rsa AAAAB3NzaC1....H6hKd user@example.com";
  #   ];
  # };

  defaultProfile.packages = with pkgs; [
    min-collect-garbage
#    strace
    #    ethtool
    tcpdump
  ];
}
