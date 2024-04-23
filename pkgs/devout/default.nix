{
  lua
, nellie
, writeFennel
, anoia
, fennel
, stdenv
, fennelrepl
, lualinux
}:
stdenv.mkDerivation {
  name = "devout";
  src = ./.;
  checkInputs = [ fennelrepl ];
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennel "devout" {
      packages = [fennel anoia nellie lua.pkgs.luafilesystem lualinux];
      mainFunction = "run";
    } ./devout.fnl} $out/bin/devout
  '';
  checkPhase = ''
    LUA_CPATH=${lualinux}/lib/lua/5.3/?.so\;$LUA_CPATH \
    fennelrepl ./test.fnl
  '';
  doCheck = true;
}
