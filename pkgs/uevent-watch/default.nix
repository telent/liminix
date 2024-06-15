{
  lua
, nellie
, lualinux
, writeFennel
, runCommand
, anoia
, fennel
, stdenv
, fennelrepl
, s6-rc-up-tree
, makeWrapper
}:
stdenv.mkDerivation {
  name = "uevent-watch";
  src = ./.;
  nativeBuildInputs = [ fennelrepl makeWrapper ];
  propagatedBuildInputs = [ s6-rc-up-tree ];
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennel "uevent-watch" {
      packages = [fennel anoia nellie lualinux];
      mainFunction = "run";
    } ./watch.fnl} $out/bin/uevent-watch
    wrapProgram $out/bin/uevent-watch --prefix PATH : "${s6-rc-up-tree}/bin"
  '';
  checkPhase = ''
    fennelrepl ./test.fnl
  '';
  doCheck = true;
}
