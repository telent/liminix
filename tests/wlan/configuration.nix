{ config, pkgs, ... }:
let
  inherit (pkgs.liminix.networking) interface hostapd;
in
rec {
  imports = [
    ../../modules/wlan.nix
    ../../modules/hostapd
    ../../modules/network
  ];

  services.hostap = config.system.service.hostapd.build {
    interface = config.hardware.networkInterfaces.wlan_24;
    params = {
      ssid = "liminix";
      country_code = "GB";
      hw_mode = "g";
      channel = "2";
      wmm_enabled = 1;
      ieee80211n = 1;
      wpa_passphrase = "colourless green ideas";
      auth_algs = 1; # 1=wpa2, 2=wep, 3=both
      wpa = 2; # 1=wpa, 2=wpa2, 3=both
      wpa_key_mgmt = "WPA-PSK";
      wpa_pairwise = "TKIP CCMP"; # auth for wpa (may not need this?)
      rsn_pairwise = "CCMP"; # auth for wpa2
    };
  };

  defaultProfile.packages = with pkgs; [ tcpdump ];
}
