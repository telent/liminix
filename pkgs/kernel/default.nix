{  stdenv
 , buildPackages
 , runCommand
 , writeText
 , lib

 , config
 , src
 , extraPatchPhase ? "echo"
 , targets ? ["vmlinux"]
} :
let
  writeConfig = import ./write-kconfig.nix { inherit lib writeText; };
  kconfigFile = writeConfig "kconfig" config;
  arch = stdenv.hostPlatform.linuxArch;
  targetNames =  map baseNameOf targets;
  inherit lib; in
stdenv.mkDerivation rec {
  name = "kernel";
  inherit src extraPatchPhase;
  hardeningDisable = ["all"];
  nativeBuildInputs = [buildPackages.stdenv.cc] ++
                      (with buildPackages.pkgs; [
                        rsync bc bison flex pkg-config
                        openssl ncurses.all perl
                      ]);
  CC = "${stdenv.cc.bintools.targetPrefix}gcc";
  HOSTCC = with buildPackages.pkgs;
    "gcc -I${openssl}/include -I${ncurses}/include";
  HOST_EXTRACFLAGS = with buildPackages.pkgs;
    "-I${openssl.dev}/include -L${openssl.out}/lib -L${ncurses.out}/lib";
  PKG_CONFIG_PATH = "./pkgconfig";
  CROSS_COMPILE = stdenv.cc.bintools.targetPrefix;
  ARCH = arch;
  KBUILD_BUILD_HOST = "liminix.builder";

  dontStrip = true;
  dontPatchELF = true;
  outputs = ["out" "headers" "modulesupport"] ++ targetNames;
  phases = [
    "unpackPhase"
    "butcherPkgconfig"
    "extraPatchPhase"
    "patchPhase"
    "patchScripts"
    "configurePhase"
    "checkConfigurationPhase"
    "buildPhase"
    "installPhase"
  ];

  patches = [
    ./cmdline-cookie.patch
    ./phram-allow-cached-mappings.patch
    ./mips-malta-fdt-from-bootloader.patch
  ];

  # this is here to work around what I think is a bug in nixpkgs
  # packaging of ncurses: it installs pkg-config data files which
  # don't produce any -L options when queried with "pkg-config --lib
  # ncurses".  For a regular build you'll never even notice, this only
  # becomes an issue if you do a nix-shell in this derivation and
  # expect "make nconfig" to work.
  butcherPkgconfig = ''
    cp -r ${buildPackages.pkgs.ncurses.dev}/lib/pkgconfig .
    chmod +w pkgconfig pkgconfig/*.pc
    for i in pkgconfig/*.pc; do test -f $i && sed -i 's/^Libs:/Libs: -L''${libdir} /'  $i;done
  '';

  patchScripts = ''
    # Make kexec pass dtb in register when invoking new kernel. The
    # code to do this is already present, but bracketed by UHI_BOOT
    # which we can't enable.
    sed -i arch/mips/kernel/machine_kexec.c -e 's/CONFIG_UHI_BOOT/CONFIG_MIPS/g'

    patchShebangs scripts/
  '';

  configurePhase = ''
    export KBUILD_OUTPUT=`pwd`
    cp ${kconfigFile} .config
    cp ${kconfigFile} .config.orig
    make V=1 olddefconfig
  '';

  checkConfigurationPhase = ''
    echo Checking required config items:
    if comm -2 -3 <(grep 'CONFIG' ${kconfigFile} |sort) <(grep 'CONFIG' .config|sort) |grep '.'    ; then
      echo -e "^^^ Some configuration lost :-(\nPerhaps you have mutually incompatible settings, or have disabled options on which these depend.\n"
      exit 0
    fi
    echo "OK"
  '';

  buildPhase = ''
    make ${lib.concatStringsSep " " targetNames} modules_prepare -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    ${CROSS_COMPILE}strip -d vmlinux
    ${lib.concatStringsSep "\n" (map (f: "cp ${f} \$${baseNameOf f}") targets)}
    cp vmlinux $out
    mkdir -p $headers
    cp -a include .config $headers/
    mkdir -p $modulesupport
    cp modules.* $modulesupport
    make clean modules_prepare
    cp -a . $modulesupport
  '';
}
