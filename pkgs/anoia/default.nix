{
  fennel
, stdenv
, lua
}:
let pname =  "anoia";
in stdenv.mkDerivation {
  inherit pname;
  version = "0.1";
  src = ./.;
  nativeBuildInputs = [ fennel ];
  buildPhase = ''
    fennel --compile init.fnl > init.lua
  '';
  installPhase = ''
    mkdir -p "$out/share/lua/${lua.luaversion}/${pname}"
    cp *.lua "$out/share/lua/${lua.luaversion}/${pname}"
  '';
}
