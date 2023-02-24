{
  lua5_3
, netlink-lua
, stdenv
, makeWrapper
}:
let
  lua = lua5_3;
  netlink = netlink-lua.override {inherit lua;};
  fennel = lua.pkgs.fennel;
in stdenv.mkDerivation rec {
  pname = "waitup";
  version = "1";

  buildInputs = [ lua netlink-lua ];
  nativeBuildInputs = [ makeWrapper  fennel ];

  src = ./.;

  installPhase = ''
    mkdir -p $out/bin $out/lib
    fennel --compile  ${./waitup.fnl} > $out/lib/waitup.lua

    makeWrapper ${lua}/bin/lua $out/bin/${pname} \
      --prefix LUA_CPATH ";" ${netlink}/lib/lua/${lua.luaversion}/\?.so \
      --add-flags $out/lib/waitup.lua
  '';
}

# to use fennel.view,
#  --prefix LUA_PATH ";" ${fennel}/share/lua/5.2/\?.lua \
