{
  callPackage
, buildPackages
, stdenvNoCC
, fetchFromGitHub

, config
, checkedConfig
}:
let
  source = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "3d7cb6b04c3f3115719235cc6866b10326de34cd";  # v5.19
    hash = "sha256-OVsIRScAnrPleW1vbczRAj5L/SGGht2+GnvZJClMUu4=";
  };

  # The kernel is huge and takes a long time just to
  # download and unpack. This derivation creates
  # a source tree in a suitable shape to build from -
  # today it just patches some scripts but as we add
  # support for boards/SoCs we expect the scope of
  # "pre-treatment" to grow

  tree = stdenvNoCC.mkDerivation {
    name = "spindled-kernel-tree";
    src = source;
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

  openwrtSource = fetchFromGitHub {
    name = "openwrt-source-tree";
    repo = "openwrt";
    owner = "openwrt";
    rev = "a5265497a4f6da158e95d6a450cb2cb6dc085cab";
    hash = "sha256-YYi4gkpLjbOK7bM2MGQjAyEBuXJ9JNXoz/JEmYf8xE8=";
  };


in rec {
  vmlinux = callPackage ./vmlinux.nix {
    inherit tree config checkedConfig;
  };

  uimage = callPackage ./uimage.nix { };

  dtb = callPackage ./dtb.nix {
    openwrt = openwrtSource;
    kernel = tree;
  };
}
