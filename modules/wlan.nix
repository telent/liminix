{ lib, pkgs, config, ...}:
let
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) stdenv wireless-regdb;
  regulatory = stdenv.mkDerivation {
    name = "regulatory.db";
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out
      cp ${wireless-regdb}/lib/firmware/regulatory.db $out/
    '';
  };
in {
  config = {
    filesystem = dir {
      lib = dir {
        firmware = dir {
          "regulatory.db" = symlink "${regulatory}/regulatory.db";
        };
      };
    };
    programs.busybox.applets = [
      "insmod" "rmmod"
    ];
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

        WLAN = "y";
        CFG80211 = "m";
        MAC80211 = "m";
        EXPERT = "y";
        CFG80211_CERTIFICATION_ONUS = "y";
        CFG80211_REQUIRE_SIGNED_REGDB = "n"; # depends on ONUS
        CFG80211_CRDA_SUPPORT = "n";
      };
    };
  };
}
