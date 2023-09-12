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
  buildInputs = with lua.pkgs; [ luafilesystem ];
  buildPhase = ''
    for f in *.fnl ; do
      fennel --compile $f > `basename $f .fnl`.lua
    done
  '';
  installPhase = ''
    mkdir -p "$out/share/lua/${lua.luaversion}/${pname}"
    cp *.lua "$out/share/lua/${lua.luaversion}/${pname}"
  '';
}
