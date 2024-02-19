{ config, pkgs, ... } :
let
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit (pkgs) writeText;
  svc = config.system.service;
  secrets-1 = {
    ssid = "Zyxel 2G (N)";
    wpa_passphrase = "diamond dogs";
  };
  secrets-2 = {
    ssid = "Zyxel 5G (AX)";
    wpa_passphrase = "diamond dogs";
  };
  baseParams = {
    country_code = "FR";
    hw_mode = "g";
    channel = 6;
    wmm_enabled = 1;
    ieee80211n = 1;
    ht_capab = "[LDPC][GF][HT40-][HT40+][SHORT-GI-40][MAX-AMSDU-7935][TX-STBC]";
    auth_algs = 1;
    wpa = 2;
    wpa_key_mgmt = "WPA-PSK";
    wpa_pairwise = "TKIP CCMP";
    rsn_pairwise = "CCMP";
  };

  modernParams = {
    hw_mode = "a";
    he_su_beamformer = 1;
    he_su_beamformee = 1;
    he_mu_beamformer = 1;
    preamble = 1;
    # Allow radar detection.
    ieee80211d = 1;
    ieee80211h = 1;
    ieee80211ac = 1;
    ieee80211ax = 1;
    vht_capab = "[MAX-MPDU-7991][SU-BEAMFORMEE][SU-BEAMFORMER][RXLDPC][SHORT-GI-80][MAX-A-MPDU-LEN-EXP3][RX-ANTENNA-PATTERN][TX-ANTENNA-PATTERN][TX-STBC-2BY1][RX-STBC-1][MU-BEAMFORMER]";
    vht_oper_chwidth = 1;
    he_oper_chwidth = 1;
    channel = 36;
    vht_oper_centr_freq_seg0_idx = 42;
    he_oper_centr_freq_seg0_idx = 42;
    require_vht = 1;
  };
  mkWifiSta = params: interface: secrets: svc.hostapd.build {
    inherit interface;
      params = params // {
        inherit (secrets) ssid wpa_passphrase;
      };
  };
in rec {
  imports = [
    ../modules/wlan.nix
    ../modules/network
    ../modules/hostapd
    ../modules/ssh
    ../modules/ntp
    ../modules/vlan
  ];

  hostname = "zyxel";

  users.root = {
    # EDIT: choose a root password and then use
    # "mkpasswd -m sha512crypt" to determine the hash.
    # It should start wirh $6$.
    passwd = "$y$j9T$f8GhLiqYmr3lc58eKhgyD0$z7P/7S9u.kq/cANZExxhS98bze/6i7aBxU6tbl7RMi.";
    openssh.authorizedKeys.keys = [
      # EDIT: you can add your ssh pubkey here
      # "ssh-rsa AAAAB3NzaC1....H6hKd user@example.com";
    ];
  };

  services.dhcpv4 =
    let iface = config.hardware.networkInterfaces.lan;
    in svc.network.dhcp.client.build { interface = iface; };

  services.defaultroute4 = svc.network.route.build {
    via = "$(output ${services.dhcpv4} address)";
    target = "default";
    dependencies = [ services.dhcpv4 ];
  };

  services.packet_forwarding = svc.network.forward.build { };
  services.sshd = svc.ssh.build {
    allowRoot = true;
  };

  services.ntp = config.system.service.ntp.build {
    pools = { "pool.ntp.org" = ["iburst"] ; };
  };

  boot.tftp = {
    serverip = "192.0.2.10";
    ipaddr = "192.0.2.12";
  };

  # wlan0 is the 2.4GHz interface.
  services.hostap-1 = mkWifiSta baseParams config.hardware.networkInterfaces.wlan0 secrets-1;
  # wlan1 is the 5GHz interface, e.g. AX capable.
  services.hostap-2 = mkWifiSta (baseParams // modernParams) config.hardware.networkInterfaces.wlan1 secrets-2;

  defaultProfile.packages = with pkgs; [ zyxel-bootconfig iw min-collect-garbage mtdutils ];
}
