{
  nellie,
  lualinux,
  writeFennel,
  anoia,
  fennel,
  stdenv,
  fennelrepl,
  s6-rc-up-tree,
}:
stdenv.mkDerivation {
  name = "uevent-watch";
  src = ./.;
  nativeBuildInputs = [ fennelrepl ];
  propagatedBuildInputs = [ s6-rc-up-tree ];
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennel "uevent-watch" {
      packages = [fennel anoia nellie lualinux s6-rc-up-tree] ;
      mainFunction = "run";
    } ./watch.fnl} $out/bin/uevent-watch
  '';
  checkPhase = ''
    fennelrepl ./test.fnl
  '';
  doCheck = true;
}
