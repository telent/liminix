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
  config-pseudofiles = pseudofile.write "config.etc"
    (config.environment.contents);

  storefs = callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    # add pseudofiles as packages to store so that the packages they
    # depend on are also added
    storeContents = [
      config-pseudofiles
    ] ++ config.packages ;
  };
in runCommand "frob-squashfs" {
    nativeBuildInputs = with buildPackages; [ squashfsTools qprint ];
} ''
    cp ${storefs} ./store.img
    chmod +w store.img
    mksquashfs - store.img -no-recovery -quiet -no-progress  -root-becomes store -p "/ d 0755 0 0"
    mksquashfs - store.img -no-recovery -quiet -no-progress  -root-becomes nix  -p "/ d 0755 0 0" -pf ${config-pseudofiles}
    cp store.img $out
''
