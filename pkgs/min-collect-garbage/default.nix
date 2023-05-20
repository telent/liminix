{
  stdenv
, nix
, cpio
, openssh
}: stdenv.mkDerivation {
  name = "min-collect-garbage";
  buildInputs = [ ];
#  propagatedBuildInputs = [ openssh ];
  src = ./.;
  makeFlags = [ "min-list-garbage" ];
  installPhase = ''
    mkdir -p $out/bin
    cp  min-collect-garbage.sh $out/bin/min-collect-garbage
    cp min-list-garbage $out/bin
  '';
}
