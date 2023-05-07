{
  stdenv
, nix
, cpio
, openssh
}: stdenv.mkDerivation {
  name = "min-copy-closure";
  buildInputs = [ ];
  propagatedBuildInputs = [ cpio openssh nix ];
  src = ./.;
  installPhase = ''
    mkdir -p $out/bin
    cp min-copy-closure.sh $out/bin/min-copy-closure
  '';
}
