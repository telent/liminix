{  stdenv
 , buildPackages
 , runCommand
 , writeText
 , lib

 , config
 , src
 , extraPatchPhase ? "true"
} :
let writeConfig = name : config: writeText name
        (builtins.concatStringsSep
          "\n"
          (lib.mapAttrsToList
            (name: value: (if value == "n" then "# CONFIG_${name} is not set" else "CONFIG_${name}=${value}"))
            config
          ));
    kconfigFile = writeConfig "kconfig" config;
    inherit lib; in
stdenv.mkDerivation rec {
  name = "kernel";
  inherit src extraPatchPhase;
  hardeningDisable = ["all"];
  nativeBuildInputs = [buildPackages.stdenv.cc] ++
                      (with buildPackages.pkgs;
                        [rsync bc bison flex pkgconfig openssl ncurses.all perl]);
  CC = "${stdenv.cc.bintools.targetPrefix}gcc";
  HOSTCC = with buildPackages.pkgs;
    "gcc -I${openssl}/include -I${ncurses}/include";
  HOST_EXTRACFLAGS = with buildPackages.pkgs;
    "-I${openssl.dev}/include -L${openssl.out}/lib -L${ncurses.out}/lib";
  PKG_CONFIG_PATH = "./pkgconfig";
  CROSS_COMPILE = stdenv.cc.bintools.targetPrefix;
  ARCH = "mips";  # kernel uses "mips" here for both mips and mipsel
  KBUILD_BUILD_HOST = "liminix.builder";

  dontStrip = true;
  dontPatchELF = true;
  outputs = ["out" "headers"];
  phases = [
    "unpackPhase"
    "butcherPkgconfig"
    "extraPatchPhase"
    "patchScripts"
    "configurePhase"
    "checkConfigurationPhase"
    "buildPhase"
    "installPhase"
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
    make vmlinux modules_prepare
  '';

  installPhase = ''
    ${CROSS_COMPILE}strip -d vmlinux
    cp vmlinux $out
    mkdir -p $headers
    cp -a include .config $headers/
  '';

}
