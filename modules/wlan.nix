{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) busybox;
  mac80211 = pkgs.mac80211.override {
    drivers = config.device.radios;
    klibBuild = config.outputs.kernel.modulesupport;
  };

in {
  config = {
    services.wlan_module = mac80211;

    kernel = rec {
      config = {
        # Most of this is necessary infra to allow wireless stack/
        # drivers to be built as module
        ASN1 = "y";
        ASYMMETRIC_KEY_TYPE = "y";
        ASYMMETRIC_PUBLIC_KEY_SUBTYPE = "y";
        CRC_CCITT = "y";
        CRYPTO = "y";
        CRYPTO_ARC4 = "y";
        CRYPTO_CBC = "y";
        CRYPTO_CCM = "y";
        CRYPTO_CMAC = "y";
        CRYPTO_GCM = "y";
        CRYPTO_HASH_INFO = "y";
        CRYPTO_USER_API = "y"; # ARC4 needs this
        CRYPTO_USER_API_HASH = "y";
        CRYPTO_USER_API_ENABLE_OBSOLETE = "y"; # ARC4 needs this
        CRYPTO_LIB_ARC4 = "y"; # for WEP
        CRYPTO_RSA = "y";
        CRYPTO_SHA1 = "y";
        ENCRYPTED_KEYS = "y";
        KEYS = "y";
      };
    };
  };
}
