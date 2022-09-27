final: prev: {
  pseudofile = final.callPackage ./pkgs/pseudofile {};
  strace = prev.strace.override { libunwind = null; };
  liminix = {
    services = final.callPackage ./pkgs/liminix-tools/services {};
    networking =  final.callPackage ./pkgs/liminix-tools/networking {};
    builders =  {
      squashfs = final.callPackage ./pkgs/liminix-tools/builders/squashfs.nix {};
    };
  };
  writeAshScript = final.callPackage ./pkgs/write-ash-script {};
  s6-init-bin =  final.callPackage ./pkgs/s6-init-bin {};
  s6-rc-database = final.callPackage ./pkgs/s6-rc-database {};

  pppoe = final.callPackage ./pkgs/pppoe {};
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
}
