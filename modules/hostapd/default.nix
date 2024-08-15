## Hostapd
## =======
##
## Hostapd (host access point daemon) enables a wireless network
## interface to act as an access point and authentication server,
## providing IEEE 802.11 access point management, and IEEE
## 802.1X/WPA/WPA2/EAP Authenticators. In less technical terms,
## this service is what you need for your Liminix device to
## provide a wireless network that clients can connect to.
##
## If you have more than one wireless network interface (e.g.
## wlan0, wlan1) you can run an instance of hostapd on each of them.

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in {
  imports = [ ../secrets ];
  options = {
    system.service.hostapd = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    system.service.hostapd = config.system.callService ./service.nix {
      interface = mkOption {
        type = liminix.lib.types.service;
      };
      params = mkOption {
        type = types.attrs;
      };
    };
  };
}
