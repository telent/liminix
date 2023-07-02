final: prev:
let
  extraPkgs = import ./pkgs/default.nix { inherit (final) callPackage; };
  inherit (final) fetchpatch;
  lua_no_readline = prev.lua5_3.overrideAttrs(o: {
    name = "lua-tty";
    preBuild = ''
      makeFlagsArray+=(PLAT="posix" SYSLIBS="-Wl,-E -ldl"  CFLAGS="-O2 -fPIC -DLUA_USE_POSIX -DLUA_USE_DLOPEN")
    '';
    # lua in nixpkgs has a postInstall stanza that assumes only
    # one output, we need to override that if we're going to
    # convert to multi-output
    # outputs = ["bin" "man" "out"];
    makeFlags =
      builtins.filter (x: (builtins.match "(PLAT|MYLIBS).*" x) == null)
        o.makeFlags;
  });

  s6 = prev.s6.overrideAttrs(o:
    let
      patch = fetchpatch {
        # add "p" directive in s6-log
        url = "https://github.com/skarnet/s6/commit/ddc76841398dfd5e18b22943727ad74b880236d3.patch";
        hash = "sha256-fBtUinBdp5GqoxgF6fcR44Tu8hakxs/rOShhuZOgokc=";
      };
      patch_needed = builtins.compareVersions o.version "2.11.1.2" <= 0;
    in {
      configureFlags = (builtins.filter
        (x: (builtins.match ".*shared.*" x) == null)
        o.configureFlags) ++
      [
        "--disable-allstatic"
        "--disable-static"
        "--enable-shared"
      ];
      hardeningDisable = ["all"];
      stripAllList = [ "sbin" "bin" ];
      patches =
        (if o ? patches then o.patches else []) ++
        (if patch_needed then [ patch ] else []);
    });
  lua = let s = lua_no_readline.override { self = s; }; in s;
in
extraPkgs // {
  mtdutils = prev.mtdutils.overrideAttrs(o: {
    patches = (if o ? patches then o.patches else []) ++ [
      ./pkgs/mtdutils/0001-mkfs.jffs2-add-graft-option.patch
    ];
  });

  rsyncSmall =
    let r = prev.rsync.overrideAttrs(o: {
          configureFlags = o.configureFlags ++ [
            "--disable-openssl"
          ];
        });
    in r.override { openssl = null; };

  chrony =
    let chrony' = prev.chrony.overrideAttrs(o: {
          configureFlags = [
            "--chronyvardir=$(out)/var/lib/chrony"
            "--disable-readline"
            "--disable-editline"
          ];
        });
    in chrony'.override {
      gnutls = null;
      nss = null;
      nspr = null;
      readline = null;
      libedit = null;
      libcap = null;
      libseccomp = null;
      # should texinfo be in nativeBuildInputs instead of
      # buildInputs?
      texinfo = null;

    };

  strace = prev.strace.override { libunwind = null; };

  kexec-tools-static = prev.kexec-tools.overrideAttrs(o: {
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

  luaFull = prev.lua;
  inherit lua;

  inherit s6;
  s6-linux-init = prev.s6-linux-init.override {
    skawarePackages = prev.skawarePackages // {
      inherit s6;
    };
  };
  s6-rc = prev.s6-rc.override {
    skawarePackages = prev.skawarePackages // {
      inherit s6;
    };
  };

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

  hostapd =
    let
      config =  [
        "CONFIG_DRIVER_NL80211=y"
        "CONFIG_IAPP=y"
        "CONFIG_IEEE80211AC=y"
        "CONFIG_IEEE80211N=y"
        "CONFIG_IEEE80211W=y"
        "CONFIG_INTERNAL_LIBTOMMATH=y"
        "CONFIG_INTERNAL_LIBTOMMATH_FAST=y"
        "CONFIG_IPV6=y"
        "CONFIG_LIBNL32=y"
        "CONFIG_PKCS12=y"
        "CONFIG_RSN_PREAUTH=y"
        "CONFIG_TLS=internal"
      ];
      h = prev.hostapd.overrideAttrs(o: {
        extraConfig = "";
        configurePhase = ''
          cat > hostapd/defconfig <<EOF
          ${builtins.concatStringsSep "\n" config}
          EOF
          ${o.configurePhase}
        '';
      });
    in h.override { openssl = null; sqlite = null; };

  dropbear = prev.dropbear.overrideAttrs (o: {
    postPatch = ''
     (echo '#define DSS_PRIV_FILENAME "/run/dropbear/dropbear_dss_host_key"'
      echo '#define RSA_PRIV_FILENAME "/run/dropbear/dropbear_rsa_host_key"'
      echo '#define ECDSA_PRIV_FILENAME "/run/dropbear/dropbear_ecdsa_host_key"'
      echo '#define ED25519_PRIV_FILENAME "/run/dropbear/dropbear_ed25519_host_key"') > localoptions.h
    '';
  });

  pppBuild = prev.ppp;
}
