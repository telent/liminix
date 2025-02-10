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
  modulesPath,
  ...
}:
let
  secrets = import ./extneder-secrets.nix;
  svc = config.system.service;
in
rec {
  boot = {
    tftp = {
      serverip = "192.168.8.148";
      ipaddr = "192.168.8.251";
    };
  };

  imports = [
    "${modulesPath}/profiles/wap.nix"
    "${modulesPath}/vlan"
    "${modulesPath}/ssh"
  ];

  hostname = "extneder";

  profile.wap = {
    interfaces = with config.hardware.networkInterfaces; [
      lan
      wlan
    ];

    wireless = {
      networks.${secrets.ssid} = {
        interface = config.hardware.networkInterfaces.wlan;
        inherit (secrets) channel wpa_passphrase;
        country_code = "GB";
        hw_mode = "g";
        wmm_enabled = 1;
        ieee80211n = 1;
      };
    };
  };

  services.sshd = svc.ssh.build { };
  users.root.passwd = lib.mkForce secrets.root.passwd;
  defaultProfile.packages = with pkgs; [
    nftables
    strace
    tcpdump
    swconfig
  ];
}
