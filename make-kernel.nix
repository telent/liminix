pkgs: config:
let
  inherit (pkgs) callPackage buildPackages stdenvNoCC fetchFromGitHub;
  source = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "3d7cb6b04c3f3115719235cc6866b10326de34cd";  # v5.19
    hash = "sha256-OVsIRScAnrPleW1vbczRAj5L/SGGht2+GnvZJClMUu4=";
  };
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
  vmlinux = callPackage ./make-vmlinux.nix {
    inherit tree;
    inherit config;
  };
}
