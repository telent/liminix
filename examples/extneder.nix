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
}: let
  secrets = import ./extneder-secrets.nix;
in rec {
  boot = {
    tftp = {
      serverip = "192.168.8.148";
      ipaddr = "192.168.8.251";
    };
  };

  imports = [
    "${modulesPath}/profiles/wap.nix"
    "${modulesPath}/vlan"
  ];

  hostname = "extneder";

  kernel = {
    config = {

      NETFILTER_XT_MATCH_CONNTRACK = "y";

      IP6_NF_IPTABLES = "y"; # do we still need these
      IP_NF_IPTABLES = "y"; # if using nftables directly

      # these are copied from rotuer and need review.
      # we're not running a firewall, so why do we need
      # nftables config?
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

  profile.wap = {
    interfaces =  with config.hardware.networkInterfaces; [
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

  users.root.passwd = lib.mkForce secrets.root.passwd;
  defaultProfile.packages = with pkgs; [nftables strace tcpdump swconfig];
}
