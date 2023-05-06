{
  stdenv
, nix
, cpio
}: stdenv.mkDerivation {
  name = "min-copy-closure";
  buildInputs = [ nix cpio ];
  src = ./.;
  installPhase = ''
    mkdir -p $out/bin
    cp min-copy-closure.sh $out/bin/nix-copy-closure
  '';
}
