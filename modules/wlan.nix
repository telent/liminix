{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) busybox;

in {
  config = {
    kernel = rec {
      config = {
        CFG80211= "y";
        MAC80211= "y";
        MAC80211_MESH= "y";
        RFKILL= "y";
        WLAN = "y";
      };
      checkedConfig = config;
    };
  };
}
