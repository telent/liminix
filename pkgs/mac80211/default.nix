# make out-of-tree modules given a backported kernel source tree

{
  extraConfig ? {}
, drivers ? [ ]
, kernel-backport
, stdenv
, writeText
, klibBuild ? null
, buildPackages
, fetchFromGitHub

, liminix
, lib
}:
let
  openwrtSrc = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "a5265497a4f6da158e95d6a450cb2cb6dc085cab";
    hash = "sha256-YYi4gkpLjbOK7bM2MGQjAyEBuXJ9JNXoz/JEmYf8xE8=";
  };
  inherit (liminix.services) oneshot longrun;
  inherit (lib.lists) foldl;
  configs = {
    ath9k = {
      WLAN_VENDOR_ATH = "y";
      ATH_COMMON = "m";
      ATH9K = "m";
      ATH9K_AHB = "y";
      # ATH9K_DEBUGFS = "y";
      # ATH_DEBUG = "y";
      BACKPORTED_ATH9K_AHB = "y";
    };
    ath10k_pci = {
      WLAN_VENDOR_ATH = "y";
      ATH_COMMON = "m";
      ATH10K = "m";
      # BACKPORTED_ATH10K_AHB = "y";
      # ATH10K_AHB = "y";
      ATH10K_PCI = "y";
      ATH10K_DEBUG = "y";
    };
    rt2800soc = {
      WLAN_VENDOR_RALINK = "y";
      RT2800SOC = "m";
      RT2X00 = "m";
    };
    mt7603e = {                     # XXX find a better name for this
      WLAN_VENDOR_RALINK = "y";
      WLAN_VENDOR_MEDIATEK = "y";
      MT7603E = "y";
    };
    mac80211_hwsim = {
      MAC80211_HWSIM = "y";
    };
  };
  kconfig = (foldl (config: d: (config // configs.${d})) {
    WLAN = "y";
    CFG80211 = "m";
    MAC80211 = "m";

    # (nixwrt comment) I am reluctant to have to enable this but
    # can't transmit on 5GHz bands without it (they are all marked
    # NO-IR)
    CFG80211_CERTIFICATION_ONUS = "y";
    # (nixwrt comment) can't get signed regdb to work rn, it just
    # gives me "loaded regulatory.db is malformed or signature is
    # missing/invalid"
    CFG80211_REQUIRE_SIGNED_REGDB = "n"; # depends on ONUS

    CFG80211_CRDA_SUPPORT = "n";

    MAC80211_MESH = "y";

  } drivers) // extraConfig;

  writeConfig = name : config: writeText name
        (builtins.concatStringsSep
          "\n"
          (lib.mapAttrsToList
            (name: value: (if value == "n" then "# CPTCFG_${name} is not set" else "CPTCFG_${name}=${value}"))
            config
          ));
  kconfigFile = writeConfig "backports_kconfig" kconfig;
  src = kernel-backport;
  CROSS_COMPILE = stdenv.cc.bintools.targetPrefix;
  CC = "${buildPackages.stdenv.cc}/bin/gcc";
  module = stdenv.mkDerivation {
    name = "mac80211";
    inherit src;

    hardeningDisable = ["all"];
    nativeBuildInputs = [buildPackages.stdenv.cc] ++
                        (with buildPackages.pkgs;
                          [bc bison flex pkgconfig openssl
                           which kmod cpio
                          ]);
    inherit CC CROSS_COMPILE;
    ARCH = "mips";  # kernel uses "mips" here for both mips and mipsel
    dontStrip = true;
    dontPatchELF = true;
    phases = [
      "unpackPhase"
      "patchFromOpenwrt"
      "configurePhase"
      "checkConfigurationPhase"
      "buildPhase"
      "installPhase"
    ];

    patchFromOpenwrt = ''
      mac80211=${openwrtSrc}/package/kernel/mac80211
      echo $mac80211
      for i in $(ls $mac80211/patches/build/ | grep -v 015-ipw200); do
        echo $i; (patch -p1 -N <$mac80211/patches/build/$i)
      done
      for i in $(ls $mac80211/patches/rt2x00/ | grep -v 009-rt2x00-don-t | grep -v 013-rt2x00-set-correct | grep -v 014 | grep -v 015 | grep -v 016); do
        echo $i; (patch -p1 -N <$mac80211/patches/rt2x00/$i)
      done
      for i in $mac80211/patches/ath/*; do echo $i; (patch -p1 -N <$i) ;done
      for i in $mac80211/patches/ath9k/*; do echo $i; (patch -p1 -N <$i) ;done
    '';

    configurePhase = ''
      cp ${kconfigFile} .config
      cp ${kconfigFile} .config.orig
      chmod +w .config .config.orig
      make V=1 CC=${CC} SHELL=`type -p bash` LEX=flex KLIB_BUILD=${klibBuild} olddefconfig
    '';

    checkConfigurationPhase = ''
      echo Checking required config items:
      if comm -2 -3 <(awk -F= '/CPTCFG/ {print $1}' ${kconfigFile} |sort) <(awk -F= '/CPTCFG/ {print $1}' .config|sort) |grep '.'    ; then
        echo -e "^^^ Some configuration lost :-(\nPerhaps you have mutually incompatible settings, or have disabled options on which these depend.\n"
        exit 0
      fi
      echo "OK"
    '';

    KBUILD_BUILD_HOST = "liminix.builder";

    buildPhase = ''
      patchShebangs scripts/
      echo  ${klibBuild}
      make V=1 SHELL=`type -p bash` KLIB_BUILD=${klibBuild} modules
      find . -name \*.ko | xargs ${CROSS_COMPILE}strip --strip-debug
    '';

    installPhase = ''
      mkdir -p $out/lib/modules/0.0
      find . -name \*.ko | cpio --make-directories -p $out/lib/modules/0.0
      depmod -b $out -v 0.0
      touch $out/load.sh
      for i in ${lib.concatStringsSep " " drivers}; do
        modprobe -S 0.0 -d $out --show-depends $i >> $out/load.sh
      done
      tac < $out/load.sh | sed 's/^insmod/rmmod/g' > $out/unload.sh
    '';
  };
in oneshot {
    name = "wlan.module";
    up = "sh ${module}/load.sh";
    down = "sh ${module}/unload.sh";
  }
