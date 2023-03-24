final: prev:
let
  extraPkgs = import ./pkgs/default.nix { inherit (final) callPackage; };
  inherit (final) fetchpatch;
  lua = prev.lua5_3.overrideAttrs(o: {
    name = "lua-tty";
    preBuild = ''
      makeFlagsArray+=(PLAT="posix" SYSLIBS="-Wl,-E -ldl"  CFLAGS="-O2 -fPIC -DLUA_USE_POSIX -DLUA_USE_DLOPEN")
    '';

    makeFlags =
      builtins.filter (x: (builtins.match "(PLAT|MYLIBS).*" x) == null)
        o.makeFlags;
  });
in
extraPkgs // {
  strace = prev.strace.override { libunwind = null; };

  kexec-tools = prev.kexec-tools.overrideAttrs(o: {
    # For kexecboot we copy kexec into a ramdisk on the system being
    # upgraded from. This is more likely to work if kexec is
    # statically linked so doesn't have dependencies on store paths that
    # may not exist on that machine. (We can't nix-copy-closure as
    # the store may not be on a writable filesystem)
    LDFLAGS = "-static";

    patches = o.patches ++ [
      (fetchpatch {
        # merge user command line options into DTB chosen
        url = "https://patch-diff.githubusercontent.com/raw/horms/kexec-tools/pull/3.patch";
        hash = "sha256-MvlJhuex9dlawwNZJ1sJ33YPWn1/q4uKotqkC/4d2tk=";
      })
      pkgs/kexec-map-file.patch
    ];
  });

  lua5_3 = let s = lua.override { self = s; }; in s;

  s6 = prev.s6.overrideAttrs(o:
    let patch = fetchpatch {
          # add "p" directive in s6-log
          url = "https://github.com/skarnet/s6/commit/ddc76841398dfd5e18b22943727ad74b880236d3.patch";
          hash = "sha256-fBtUinBdp5GqoxgF6fcR44Tu8hakxs/rOShhuZOgokc=";
        };
        patch_needed = builtins.compareVersions o.version "2.11.1.2" <= 0;
    in {
      patches =
        (if o ? patches then o.patches else []) ++
        (if patch_needed then [ patch ] else []);
    });

  nftables = prev.nftables.overrideAttrs(o: {
    configureFlags = [
      "--disable-debug"
      "--disable-python"
      "--with-mini-gmp"
      "--without-cli"
    ];
  });

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

  hostapd = prev.hostapd.override { sqlite = null; };

  dropbear = prev.dropbear.overrideAttrs (o: {
    postPatch = ''
     (echo '#define DSS_PRIV_FILENAME "/run/dropbear/dropbear_dss_host_key"'
      echo '#define RSA_PRIV_FILENAME "/run/dropbear/dropbear_rsa_host_key"'
      echo '#define ECDSA_PRIV_FILENAME "/run/dropbear/dropbear_ecdsa_host_key"'
      echo '#define ED25519_PRIV_FILENAME "/run/dropbear/dropbear_ed25519_host_key"') > localoptions.h
    '';
  });

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
}
