{
  stdenv
, busybox
, buildPackages
, callPackage
, pseudofile
, runCommand
, writeText
} : filesystem :
let
  pseudofiles = pseudofile.write "files.pf" filesystem;

  storefs = callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    # 1) Every required package is referenced from somewhere
    # outside /nix/store. 2) Every file outside the store is
    # specified by config.filesystem. 3) Therefore, closing over
    # the pseudofile will give us all the needed packages
    storeContents = [ pseudofiles ];
  };
in runCommand "frob-squashfs" {
    nativeBuildInputs = with buildPackages; [ squashfsTools qprint ];
} ''
    cp ${storefs} ./store.img
    chmod +w store.img
    mksquashfs - store.img -exit-on-error -no-recovery -quiet -no-progress  -root-becomes store -p "/ d 0755 0 0"
    mksquashfs - store.img -exit-on-error -no-recovery -quiet -no-progress  -root-becomes nix  -p "/ d 0755 0 0" -pf ${pseudofiles}
    cp store.img $out
''
