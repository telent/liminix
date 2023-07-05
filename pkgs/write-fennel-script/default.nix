{
  lua
, lib
, fennel
, stdenv
}:
name : packages : source :
  let
    luapath = builtins.map
      (f:
        "${f}/share/lua/${lua.luaversion}/?.lua;" +
        "${f}/share/lua/${lua.luaversion}/?/init.lua;")
      packages;
    luacpath = builtins.map (f: "${f}/lib/lua/${lua.luaversion}/?.so;") packages;
  in stdenv.mkDerivation {
    inherit name;
    src = ./.;
    nativeBuildInputs = [ fennel ];
    buildPhase = ''
      (
       echo "#!${lua}/bin/lua"
       echo "package.path = ${lib.strings.escapeShellArg luapath} .. package.path"
       echo "package.cpath = ${lib.strings.escapeShellArg luacpath} .. package.cpath"
       fennel --correlate --compile ${source}
      ) >  ${name}.lua
    '';
    installPhase = ''
      cp ${name}.lua $out
      chmod +x $out
    '';
  }
