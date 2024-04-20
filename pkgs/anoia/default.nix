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
  doCheck = true;
  checkPhase = "make test";
  installPhase = ''
    mkdir -p "$out/share/lua/${lua.luaversion}/${pname}"
    cp *.lua "$out/share/lua/${lua.luaversion}/${pname}"
  '';
}
