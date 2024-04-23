{
  lua
, nellie
, writeFennel
, anoia
, fennel
, stdenv
, fennelrepl
, minisock
}:
stdenv.mkDerivation {
  name = "devout";
  src = ./.;
  checkInputs = [ fennelrepl ];
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennel "devout" {
      packages = [fennel anoia nellie lua.pkgs.luafilesystem minisock];
      mainFunction = "run";
    } ./devout.fnl} $out/bin/devout
  '';
  checkPhase = ''
    LUA_CPATH=${minisock}/lib/lua/5.3/?.so\;$LUA_CPATH \
    fennelrepl ./test.fnl
  '';
  doCheck = true;
}
