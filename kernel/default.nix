{
  callPackage
, buildPackages
, stdenvNoCC
, fetchFromGitHub

, config
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
    phases = [ "unpackPhase" "patchScripts" "installPhase" ];
    patchScripts = ''
      patchShebangs scripts/
      # substituteInPlace Makefile --replace /bin/pwd ${buildPackages.pkgs.coreutils}/bin/pwd
    '';
    installPhase = ''
      mkdir -p $out
      cp -a . $out
    '';
  };
in
{
  vmlinux = callPackage ./vmlinux.nix {
    inherit tree;
    inherit config;
  };
}
