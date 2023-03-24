{
  luaSmall
, netlink-lua
, stdenv
, makeWrapper
}:
let
  lua = luaSmall;
  netlink = netlink-lua.override {inherit lua;};
  fennel = lua.pkgs.fennel;
in stdenv.mkDerivation rec {
  pname = "ifwait";
  version = "1";
  phases = [ "installPhase" ];

  buildInputs = [ lua netlink ];
  nativeBuildInputs = [ makeWrapper fennel ];

  LUA_CPATH = "${netlink}/lib/lua/${lua.luaversion}/\?.so"; # for nix-shell

  installPhase = ''
    mkdir -p $out/bin $out/lib
    fennel --compile  ${./ifwait.fnl} > $out/lib/${pname}.lua

    makeWrapper ${lua}/bin/lua $out/bin/${pname} \
      --prefix LUA_CPATH ";" ${netlink}/lib/lua/${lua.luaversion}/\?.so \
      --add-flags $out/lib/${pname}.lua
    # makeWrapper adds a shebang for bash
    sed -i -e '1c#!/bin/sh' $out/bin/${pname}
  '';
}

# to use fennel.view,
#  --prefix LUA_PATH ";" ${fennel}/share/lua/5.2/\?.lua \
