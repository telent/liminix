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
    for i in min-copy-closure liminix-rebuild; do
      echo $i
      cp ''${i}.sh $out/bin/$i
    done
  '';
}
