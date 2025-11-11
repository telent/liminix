final: prev:
let
  isCross = final.stdenv.buildPlatform != final.stdenv.hostPlatform;
  crossOnly = pkg: amendFn: if isCross then (amendFn pkg) else pkg;
  extraPkgs = import ./pkgs/default.nix {
    inherit (final) lib callPackage;
  };
  inherit (final) fetchpatch lib;
  luaHost =
    let
      l = prev.lua5_3.overrideAttrs (o: {
        name = "lua-tty";
        preBuild = ''
          makeFlagsArray+=(PLAT="posix" SYSLIBS="-Wl,-E -ldl"  CFLAGS="-O2 -fPIC -DLUA_USE_POSIX -DLUA_USE_DLOPEN")
        '';
        # lua in nixpkgs has a postInstall stanza that assumes only
        # one output, we need to override that if we're going to
        # convert to multi-output
        # outputs = ["bin" "man" "out"];
        makeFlags = builtins.filter (x: (builtins.match "(PLAT|MYLIBS).*" x) == null) o.makeFlags;
      });
    in
    l.override {
      self = l;
      packageOverrides =
        lua-final: lua-prev:
        let
          openssl = final.opensslNoThreads;
        in
        {
          cqueues = lua-prev.cqueues.overrideAttrs (o: {
            externalDeps = [
              {
                name = "CRYPTO";
                dep = openssl;
              }
              {
                name = "OPENSSL";
                dep = openssl;
              }
            ];
          });
          luaossl = lua-prev.luaossl.overrideAttrs (o: {
            externalDeps = [
              {
                name = "CRYPTO";
                dep = openssl;
              }
              {
                name = "OPENSSL";
                dep = openssl;
              }
            ];
            name = "${o.name}-218";
            patches = [
              (fetchpatch {
                url = "https://patch-diff.githubusercontent.com/raw/wahern/luaossl/pull/218.patch";
                hash = "sha256-2GOliY4/RUzOgx3rqee3X3szCdUVxYDut7d+XFcUTJw=";
              })
            ];
          });
        };
    };

  s6 = prev.s6.overrideAttrs (
    o:
    let
      patch = fetchpatch {
        # add "p" directive in s6-log
        url = "https://github.com/skarnet/s6/commit/ddc76841398dfd5e18b22943727ad74b880236d3.patch";
        hash = "sha256-fBtUinBdp5GqoxgF6fcR44Tu8hakxs/rOShhuZOgokc=";
      };
      patch_needed = builtins.compareVersions o.version "2.11.1.2" <= 0;
    in
    {
      configureFlags =
        (builtins.filter (x: (builtins.match ".*shared.*" x) == null) o.configureFlags)
        ++ [
          "--disable-allstatic"
          "--disable-static"
          "--enable-shared"
        ];
      hardeningDisable = [ "all" ];
      stripAllList = [
        "sbin"
        "bin"
      ];
      patches = (if o ? patches then o.patches else [ ]) ++ (if patch_needed then [ patch ] else [ ]);
    }
  );
in
extraPkgs
// {
  # liminix library functions
  lim = {
    parseInt = s: (builtins.fromTOML "r=${s}").r;
    orEmpty = x: if x != null then x else [ ];
  };

  # keep these alphabetical

  btrfs-progs = crossOnly prev.btrfs-progs (
    d:
    d.override {
      udevSupport = false;
      udev = null;
    }
  );

  chrony =
    let
      chrony' = prev.chrony.overrideAttrs (o: {
        configureFlags = [
          "--chronyvardir=$(out)/var/lib/chrony"
          "--sbindir=$(out)/bin"
          "--chronyrundir=/run/chrony"
          "--disable-readline"
          "--disable-editline"
        ];
      });
    in
    chrony'.override {
      gnutls = null;
      libedit = null;
      libseccomp = null;
      libcap = null;
      # should texinfo be in nativeBuildInputs instead of
      # buildInputs?
      texinfo = null;
    }
    // lib.optionalAttrs (lib.versionOlder lib.version "24.10") {
      nss = null;
      nspr = null;
      readline = null;
    };

  # clevis without luks/tpm
  clevis = crossOnly prev.clevis (
    d:
    let
      c = d.overrideAttrs (o: {
        outputs = [ "out" ];
        preConfigure = ''
          rm -rf src/luks
          sed -i -e '/luks/d' src/meson.build
        '';
      });
    in
    c.override {
      asciidoc = null;
      cryptsetup = null;
      luksmeta = null;
      tpm2-tools = null;
    }
  );

  dnsmasq =
    let
      d = prev.dnsmasq.overrideAttrs (o: {
        preBuild = ''
          makeFlagsArray=("COPTS=")
        '';
      });
    in
    d.override {
      dbusSupport = false;
      nettle = null;
    };

  dropbear = crossOnly prev.dropbear (
    d:
    d.overrideAttrs (o: rec {
      # nixpkgs 25.05 contains newer dropbear (2025.87) than this,
      # we can drop this override when that's ready
      version = "2024.85";
      src = final.fetchurl {
        url = "https://matt.ucc.asn.au/dropbear/releases/dropbear-${version}.tar.bz2";
        sha256 = "sha256-hrA2xDOmnYnOUeuuM11lxHc4zPkNE+XrD+qDLlVtpQI=";
      };
      patches =
        # in 24.11 we need to update nixpkgs patch for new version of dropbear
        let
          passPath = final.runCommand "pass-path" { } ''
            sed < ${builtins.head o.patches} -e 's,svr-chansession.c,src/svr-chansession.c,g' > $out
          '';
        in
        [
          (if (lib.versionOlder o.version "2024") then passPath else (builtins.head o.patches))
          ./pkgs/dropbear/add-authkeyfile-option.patch
        ];
      postPatch = ''
        (echo '#define DSS_PRIV_FILENAME "/run/dropbear/dropbear_dss_host_key"'
         echo '#define RSA_PRIV_FILENAME "/run/dropbear/dropbear_rsa_host_key"'
         echo '#define ECDSA_PRIV_FILENAME "/run/dropbear/dropbear_ecdsa_host_key"'
         echo '#define ED25519_PRIV_FILENAME "/run/dropbear/dropbear_ed25519_host_key"') > localoptions.h
      '';
    })
  );

  elfutils = crossOnly prev.elfutils (
    d:
    let
      e = d.overrideAttrs (o: {
        configureFlags = o.configureFlags ++ [
          "ac_cv_has_stdatomic=no"
        ];
      });
    in
    e.override {
      enableDebuginfod = false;
    }
  );

  hostapd =
    let
      config = [
        "CONFIG_DRIVER_NL80211=y"
        "CONFIG_IAPP=y"
        "CONFIG_IEEE80211AC=y"
        "CONFIG_IEEE80211AX=y"
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
      h = prev.hostapd.overrideAttrs (o: {
        extraConfig = "";
        configurePhase = ''
          cat > hostapd/defconfig <<EOF
          ${builtins.concatStringsSep "\n" config}
          EOF
          ${o.configurePhase}
        '';
      });
    in
    h.override {
      openssl = null;
      sqlite = null;
    };

  # berlekey db needs libatomic which we haven't figured out yet.
  # disabling it means we don't have arpd
  iproute2 = crossOnly prev.iproute2 (d: d.override { db = null; });

  kexec-tools-static = prev.kexec-tools.overrideAttrs (o: {
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

  libadwaita = prev.libadwaita.overrideAttrs (o: {
    # tests fail with a message
    # Gdk-DEBUG: error: XDG_RUNTIME_DIR is invalid or not set in the environment.
    doCheck = false;
  });

  lua = luaHost;

  mtdutils =
    (prev.mtdutils.overrideAttrs (o: {

      src = final.fetchgit {
        url = "git://git.infradead.org/mtd-utils.git";
        rev = "77981a2888c711268b0e7f32af6af159c2288e23";
        hash = "sha256-pHunlPOuvCRyyk9qAiR3Kn3cqS/nZHIxsv6m4nsAcbk=";
      };

      patches = (if o ? patches then o.patches else [ ]) ++ [
        ./pkgs/mtdutils/0001-mkfs.jffs2-add-graft-option.patch
      ];
    })).override
      { util-linux = final.util-linux-small; };

  nftables = prev.nftables.overrideAttrs (o: {
    configureFlags = [
      "--disable-debug"
      "--disable-python"
      "--with-mini-gmp"
      "--without-cli"
    ];
  });

  opensslNoThreads = prev.openssl.overrideAttrs (
    o: with final; {
      pname = "${o.pname}-nothreads";
      # openssl with threads requires stdatomic which drags in libgcc
      # as a dependency
      preConfigure =
        let
          arch = if stdenv.hostPlatform.gcc ? arch then "-march=${stdenv.hostPlatform.gcc.arch}" else "";
          soft = if arch == "-march=24kc" then "-msoft-float" else "";
        in
        ''
          configureFlagsArray+=(no-threads no-asm CFLAGS="${arch} ${soft}")
        '';
      # don't need or want this bash script
      postInstall = o.postInstall + "rm $bin/bin/c_rehash\n";
    }
  );

  pppBuild = prev.ppp;

  qemuLim =
    let
      inherit (final) lib;
      q = prev.qemu.overrideAttrs (o: {
        patches = o.patches ++ [
          ./pkgs/qemu/arm-image-friendly-load-addr.patch
          (final.fetchpatch {
            url = "https://lore.kernel.org/qemu-devel/20220322154658.1687620-1-raj.khem@gmail.com/raw";
            hash = "sha256-jOsGka7xLkJznb9M90v5TsJraXXTAj84lcphcSxjYLU=";
          })
        ];
        buildInputs = o.buildInputs ++ [ final.libslirp ];
      });
      overrides = {
        hostCpuTargets = map (f: "${f}-softmmu") [
          "arm"
          "aarch64"
          "mips"
          "mipsel"
        ];
        sdlSupport = false;
        numaSupport = false;
        seccompSupport = false;
        usbredirSupport = false;
        libiscsiSupport = false;
        tpmSupport = false;
        uringSupport = false;
        capstoneSupport = false;
      }
      // lib.optionalAttrs (lib.versionOlder lib.version "24.10") {
        texinfo = null;
        nixosTestRunner = true;
      }
      // lib.optionalAttrs (lib.versionAtLeast lib.version "25.04") {
        minimal = true;
      };
    in
    q.override overrides;
  rsyncSmall =
    let
      r = prev.rsync.overrideAttrs (o: {
        configureFlags = o.configureFlags ++ [ "--disable-openssl" ];
      });
    in
    r.override { openssl = null; };

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

  strace = prev.strace.override { libunwind = null; };

  ubootQemuAarch64 = final.buildUBoot {
    defconfig = "qemu_arm64_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    filesToInstall = [ "u-boot.bin" ];
  };

  ubootQemuArm = final.buildUBoot {
    defconfig = "qemu_arm_defconfig";
    extraMeta.platforms = [ "armv7l-linux" ];
    filesToInstall = [ "u-boot.bin" ];
    extraConfig = ''
      CONFIG_CMD_UBI=y
      CONFIG_CMD_UBIFS=y
      CONFIG_BOOTSTD=y
      CONFIG_BOOTMETH_DISTRO=y
      CONFIG_LZMA=y
      CONFIG_CMD_LZMADEC=y
      CONFIG_SYS_BOOTM_LEN=0x1000000
    '';
  };

  ubootQemuMips = final.buildUBoot {
    defconfig = "malta_defconfig";
    extraMeta.platforms = [ "mips-linux" ];
    filesToInstall = [ "u-boot.bin" ];
    # define the prompt to be the same as arm{32,64} so
    # we can use the same expect script for both
    extraPatches = [ ./pkgs/u-boot/0002-virtio-init-for-malta.patch ];
    extraConfig = ''
      CONFIG_SYS_PROMPT="=> "
      CONFIG_VIRTIO=y
      CONFIG_AUTOBOOT=y
      CONFIG_DM_PCI=y
      CONFIG_VIRTIO_PCI=y
      CONFIG_VIRTIO_NET=y
      CONFIG_VIRTIO_BLK=y
      CONFIG_VIRTIO_MMIO=y
      CONFIG_QFW_MMIO=y
      CONFIG_FIT=y
      CONFIG_LZMA=y
      CONFIG_CMD_LZMADEC=y
      CONFIG_SYS_BOOTM_LEN=0x1000000
      CONFIG_SYS_MALLOC_LEN=0x400000
      CONFIG_MIPS_BOOT_FDT=y
      CONFIG_OF_LIBFDT=y
      CONFIG_OF_STDOUT_VIA_ALIAS=y
    '';
  };

  libusb1 = crossOnly prev.libusb1 (
    d:
    let
      u = d.overrideAttrs (o: {
        # don't use gcc libatomic because it vastly increases the
        # closure size
        preConfigure = "sed -i.bak /__atomic_fetch_add_4/c\: configure.ac";
      });
    in
    u.override {
      enableUdev = false;
      withDocs = false;
    }
  );

  util-linux-small = prev.util-linux.override {
    ncursesSupport = false;
    pamSupport = false;
    systemdSupport = false;
    nlsSupport = false;
    translateManpages = false;
    capabilitiesSupport = false;
  };

  xl2tpd = prev.xl2tpd.overrideAttrs (o: {
    patches = [ ./pkgs/xl2tpd-exit-on-close.patch ];
  });
}
