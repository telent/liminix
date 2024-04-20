{
  lua
, nellie
, writeFennel
, anoia
, fennel
, stdenv
, fennelrepl
}:
stdenv.mkDerivation {
  name = "devout";
  src = ./.;
  checkInputs = [ fennelrepl ];
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennel "devout" {
      packages = [fennel anoia nellie lua.pkgs.luafilesystem];
      mainFunction = "run";
    } ./devout.fnl} $out/bin/devout
  '';
  checkPhase = ''
    fennelrepl ./test.fnl
  '';
  doCheck = true;
}
