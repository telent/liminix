pkgs: config:
let
  inherit (pkgs) buildPlatform callPackage stdenvNoCC closureInfo stdenv writeText s6-rc;

  # we need to generate s6 db,  by generating closure of all
  # config.services and calling s6-rc-compile on them
  allServices = closureInfo {
    rootPaths = builtins.attrValues config.services;
  };
  s6db = stdenvNoCC.mkDerivation  {
    name = "s6-rc-db";
    nativeBuildInputs = [pkgs.buildPackages.s6-rc];
    builder = writeText "find-s6-services" ''
    source $stdenv/setup
    mkdir -p $out
    srcs=""
    shopt -s nullglob
    for i in $(cat  ${allServices}/store-paths ); do
      if test -d $i; then
        for j in $i/* ; do
          if test -f $j/type ; then
            srcs="$srcs $i"
          fi
        done
      fi
    done
    echo s6-rc-compile $out/compiled $srcs
    s6-rc-compile $out/compiled $srcs
    '';
  };
  makeSquashfs = callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    storeContents = [ s6db ] ++ config.packages ;
    # comp =  "xz -Xdict-size 100%"
  };
in  makeSquashfs
