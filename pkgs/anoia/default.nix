{
  fennel
, stdenv
, lua
, lualinux
}:
let pname =  "anoia";
in stdenv.mkDerivation {
  inherit pname;
  version = "0.1";
  src = ./.;
  nativeBuildInputs = [ fennel ];
  buildInputs = with lua.pkgs; [ luafilesystem lualinux ];
  outputs = [ "out" "dev" ];

  doCheck = true;

  installPhase = ''
    mkdir -p "$out/share/lua/${lua.luaversion}/${pname}"
    cp *.lua "$out/share/lua/${lua.luaversion}/${pname}"

    mkdir -p "$dev/share/lua/${lua.luaversion}/${pname}"
    cp assert.fnl "$dev/share/lua/${lua.luaversion}/${pname}"
  '';
}
