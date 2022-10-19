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
        # if/when we switch to using backported mac80211 drivers built
        # as modules, based on nixwrt code we expect we will need this config
        # to enable them
        # "ASN1" = "y";
        # "ASYMMETRIC_KEY_TYPE" = "y";
        # "ASYMMETRIC_PUBLIC_KEY_SUBTYPE" = "y";
        # "CRC_CCITT" = "y";
        # "CRYPTO" = "y";
        # "CRYPTO_ARC4" = "y";
        # "CRYPTO_CBC" = "y";
        # "CRYPTO_CCM" = "y";
        # "CRYPTO_CMAC" = "y";
        # "CRYPTO_GCM" = "y";
        # "CRYPTO_HASH_INFO" = "y";
        # "CRYPTO_LIB_ARC4" = "y";
        # "CRYPTO_RSA" = "y";
        # "CRYPTO_SHA1" = "y";
        # "ENCRYPTED_KEYS" = "y";
        # "KEYS" = "y";
      };
    };
  };
}
