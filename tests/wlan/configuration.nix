{ config, pkgs, lib, ... } :
let
  inherit (pkgs.liminix.networking) interface address hostapd route dnsmasq;
  inherit (pkgs.liminix.services) oneshot longrun bundle target output;
in rec {
  services.loopback =
    let iface = interface { type = "loopback"; device = "lo";};
    in bundle {
      name = "loopback";
      contents = [
        (address iface { family = "inet4"; address ="127.0.0.1"; prefixLength = 8;})
        (address iface { family = "inet6"; address ="::1"; prefixLength = 128;})
      ];
    };

  services.wlan = interface { type = "hardware"; device = "wlan0"; };

  services.hostap = hostapd (services.wlan) {
    params = {
      ssid = "liminix";
      country_code = "GB";
      hw_mode="g";
      channel = "2";
      wmm_enabled = 1;
      ieee80211n = 1;
      wpa_passphrase = "colourless green ideas";
      auth_algs = 1; # 1=wpa2, 2=wep, 3=both
      wpa = 2;       # 1=wpa, 2=wpa2, 3=both
      wpa_key_mgmt = "WPA-PSK";
      wpa_pairwise = "TKIP CCMP";   # auth for wpa (may not need this?)
      rsn_pairwise = "CCMP";        # auth for wpa2
    };
  };

  services.default = target {
    name = "default";
    contents = with services; [
      loopback
      hostap
    ];
  };
  defaultProfile.packages = with pkgs;  [ tcpdump ] ;
}
