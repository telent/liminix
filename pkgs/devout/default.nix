{
  nellie,
  writeFennel,
  anoia,
  fennel,
  stdenv,
  fennelrepl,
  lualinux,
}:
stdenv.mkDerivation {
  name = "devout";
  src = ./.;
  nativeBuildInputs = [ fennelrepl ];
  postBuild = ''
    LUA_CPATH=${lualinux}/lib/lua/5.3/?.so\;$LUA_CPATH \
    fennelrepl ./test.fnl
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennel "devout" {
      packages = [fennel anoia nellie lualinux];
      mainFunction = "run";
    } ./devout.fnl} $out/bin/devout
  '';
}
