{
  stdenv
, busybox
, buildPackages
, callPackage
, pseudofile
, runCommand
, writeText
} : config :
let
  pseudofiles =
    pseudofile.write "config.etc" (config.environment.contents);

  storefs = callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    # 1) Every required package is referenced from somewhere
    # outside /nix/store. 2) Every file outside the store is
    # specified by config.environment. 3) Therefore, closing over
    # the pseudofile will give us all the needed packages
    storeContents = [ pseudofiles ];
  };
in runCommand "frob-squashfs" {
    nativeBuildInputs = with buildPackages; [ squashfsTools qprint ];
} ''
    cp ${storefs} ./store.img
    chmod +w store.img
    mksquashfs - store.img -no-recovery -quiet -no-progress  -root-becomes store -p "/ d 0755 0 0"
    mksquashfs - store.img -no-recovery -quiet -no-progress  -root-becomes nix  -p "/ d 0755 0 0" -pf ${pseudofiles}
    cp store.img $out
''
