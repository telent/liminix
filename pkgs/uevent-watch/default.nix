{
  lua
, nellie
, writeFennelScript
, runCommand
, anoia
, fennel
, stdenv
, fennelrepl
}:
stdenv.mkDerivation {
  name = "uevent-watch";
  src = ./.;
  nativeBuildInputs = [ fennelrepl ];
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennelScript "uevent-watch" [fennel anoia nellie lua.pkgs.luafilesystem] ./watch.fnl} $out/bin/uevent-watch
  '';
  checkPhase = ''
    fennelrepl ./test.fnl
  '';
  doCheck = true;
}
