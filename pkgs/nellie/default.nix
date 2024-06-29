{ lua, stdenv }:

let pname = "nellie";
in lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.1.1-1";

  src = ./.;

  buildPhase = "$CC -shared -l lua -o nellie.so nellie.c";

  # for the checks to work you need to
  # nix-build--option sandbox false
  # otherwise the sandbox doesn't see any uevent messages

  # doCheck = stdenv.hostPlatform == stdenv.buildPlatform;

  checkPhase = ''
    export LUA_CPATH=./?.so
    lua test.lua
  '';

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp  nellie.so "$out/lib/lua/${lua.luaversion}/"
  '';

}
