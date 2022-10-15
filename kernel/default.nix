{
  callPackage
, buildPackages
, stdenvNoCC
, fetchFromGitHub

, config
, checkedConfig
, sources
}:
let
  # The kernel is huge and takes a long time just to
  # download and unpack. This derivation creates
  # a source tree in a suitable shape to build from -
  # today it just patches some scripts but as we add
  # support for boards/SoCs we expect the scope of
  # "pre-treatment" to grow

  tree = stdenvNoCC.mkDerivation {
    name = "spindled-kernel-tree";
    src = sources.kernel;
    phases = [ "unpackPhase" "patchPhase" "patchScripts" "installPhase" ];
    patches = [ ./random.patch ];
    patchScripts = ''
      patchShebangs scripts/
    '';
    installPhase = ''
      mkdir -p $out
      cp -a . $out
    '';
  };

in rec {
  vmlinux = callPackage ./vmlinux.nix {
    inherit tree config checkedConfig;
  };

  uimage = callPackage ./uimage.nix { };

  dtb = callPackage ./dtb.nix {
    openwrt = sources.openwrt;
    kernel = tree;
  };
}
