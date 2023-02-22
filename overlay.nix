final: prev: {
  pseudofile = final.callPackage ./pkgs/pseudofile {};
  strace = prev.strace.override { libunwind = null; };
  liminix = {
    services = final.callPackage ./pkgs/liminix-tools/services {};
    networking =  final.callPackage ./pkgs/liminix-tools/networking {};
    builders =  {
      squashfs = final.callPackage ./pkgs/liminix-tools/builders/squashfs.nix {};
      kernel = final.callPackage ./pkgs/kernel {};
    };
  };
  writeAshScript = final.callPackage ./pkgs/write-ash-script {};
  s6-init-bin =  final.callPackage ./pkgs/s6-init-bin {};
  s6-rc-database = final.callPackage ./pkgs/s6-rc-database {};

  dnsmasq =
    let d =  prev.dnsmasq.overrideAttrs(o: {
          preBuild =  ''
              makeFlagsArray=("COPTS=")
          '';
        });
    in d.override {
    dbusSupport = false;
    nettle = null;
  };

  mips-vm = final.callPackage ./pkgs/mips-vm {};
  pppoe = final.callPackage ./pkgs/pppoe {};

  kernel-backport = final.callPackage ./pkgs/kernel-backport {};
  mac80211 = final.callPackage ./pkgs/mac80211 {};

  pppBuild = prev.ppp;
  ppp =
    (prev.ppp.override {
      libpcap = null;
    }).overrideAttrs (o : {
      stripAllList = [ "bin" ];
      buildInputs = [];

      # patches =
      #   o.patches ++
      #   [(final.fetchpatch {
      #     name = "ipv6-script-options.patch";
      #     url = "https://github.com/ppp-project/ppp/commit/874c2a4a9684bf6938643c7fa5ff1dd1cf80aea4.patch";
      #     sha256 = "sha256-K46CKpDpm1ouj6jFtDs9IUMHzlRMRP+rMPbMovLy3o4=";
      #   })];

      postPatch = ''
        sed -i -e  's@_PATH_VARRUN@"/run/"@'  pppd/main.c
        sed -i -e  's@^FILTER=y@# FILTER unset@'  pppd/Makefile.linux
        sed -i -e  's/-DIPX_CHANGE/-UIPX_CHANGE/g'  pppd/Makefile.linux
      '';
      buildPhase = ''
        runHook preBuild
        make -C pppd CC=$CC USE_TDB= HAVE_MULTILINK= USE_EAPTLS= USE_CRYPT=y
        make -C pppd/plugins/pppoe CC=$CC
        make -C pppd/plugins/pppol2tp CC=$CC
        runHook postBuild;
      '';
      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/lib/pppd/2.4.9
        cp pppd/pppd pppd/plugins/pppoe/pppoe-discovery $out/bin
        cp pppd/plugins/pppoe/pppoe.so $out/lib/pppd/2.4.9
        cp pppd/plugins/pppol2tp/{open,pppo}l2tp.so $out/lib/pppd/2.4.9
        runHook postInstall
      '';
      postFixup = "";
    });


  # we need to build real lzma instead of using xz, because the lzma
  # decoder in u-boot doesn't understand streaming lzma archives
  # ("Stream with EOS marker is not supported") and xz can't create
  # non-streaming ones.  See
  # https://sourceforge.net/p/squashfs/mailman/message/26599379/

  lzma = final.stdenv.mkDerivation {
    pname = "lzma";
    version = "4.32.7";
    configureFlags = [ "--enable-static" "--disable-shared"];
    src = final.buildPackages.fetchurl {
      url = "https://tukaani.org/lzma/lzma-4.32.7.tar.gz";
      sha256 = "0b03bdvm388kwlcz97aflpr3ir1zpa3m0bq3s6cd3pp5a667lcwz";
    };
  };

  # these are packages for the build system not the host/target

  tufted = final.callPackage ./pkgs/tufted {};
  routeros = final.callPackage ./pkgs/routeros {};
  go-l2tp = final.callPackage ./pkgs/go-l2tp {};
}
