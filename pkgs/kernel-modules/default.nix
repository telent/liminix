{
  stdenv
, buildPackages
, kernelSrc  ? null
, modulesupport ? null
, targets ? []
, kconfig ? {}
, openssl
, writeText
, lib
}:
let
  writeConfig = import ../kernel/write-kconfig.nix { inherit lib writeText; };
  arch = stdenv.hostPlatform.linuxArch;
in stdenv.mkDerivation {
  name = "kernel-modules";

  nativeBuildInputs = [buildPackages.stdenv.cc] ++
                      (with buildPackages.pkgs; [
                        bc bison flex
                        openssl
                        cpio
                        kmod
                      ]);
  CC = "${stdenv.cc.bintools.targetPrefix}gcc";
  HOST_EXTRACFLAGS = with buildPackages.pkgs;
    "-I${buildPackages.openssl.dev}/include -L${buildPackages.openssl.out}/lib";
  CROSS_COMPILE = stdenv.cc.bintools.targetPrefix;
  ARCH = arch;
  KBUILD_BUILD_HOST = "liminix.builder";

  buildPhase = ''
    cat ${writeConfig "kconfig" kconfig}  > .more-config
    cat .more-config >> .config
    make olddefconfig
    for v in $(cat .more-config) ; do grep $v .config || (echo Missing $v && exit 1);done
    make modules
  '';
  src =  modulesupport;
  installPhase = ''
    mkdir -p $out/lib/modules/0.0
    find . -name \*.ko | cpio --verbose --make-directories -p $out/lib/modules/0.0
    depmod -b $out -v 0.0
    touch $out/load.sh
    for i in ${lib.concatStringsSep " " targets}; do
      modprobe -S 0.0 -d $out --show-depends $i >> $out/load.sh
    done
    tac < $out/load.sh | sed 's/^insmod/rmmod/g' > $out/unload.sh
  '';
}
