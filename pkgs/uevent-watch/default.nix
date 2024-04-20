{
  lua
, nellie
, writeFennel
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
    cp -p ${writeFennel "uevent-watch" {
      packages = [fennel anoia nellie lua.pkgs.luafilesystem];
      mainFunction = "run";
    } ./watch.fnl} $out/bin/uevent-watch
  '';
  checkPhase = ''
    fennelrepl ./test.fnl
  '';
  doCheck = true;
}
