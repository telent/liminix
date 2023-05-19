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
  makeFlags = [ "min-list-garbage" ];
  installPhase = ''
    mkdir -p $out/bin
    for i in min-copy-closure liminix-rebuild; do
      echo $i
      cp ''${i}.sh $out/bin/$i
    done
    cp min-list-garbage $out/bin
  '';
}
