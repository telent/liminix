{
  lua
, lib
, fennel
, stdenv
}:
name :
{
  packages ? [],
  correlate ? false,
  mainFunction ? null
} @ options : source :
  let
    luapath = builtins.map
      (f:
        "${f}/share/lua/${lua.luaversion}/?.lua;" +
        "${f}/share/lua/${lua.luaversion}/?/init.lua;")
      packages;
    luacpath = builtins.map (f: "${f}/lib/lua/${lua.luaversion}/?.so;") packages;
    luaFlags = lib.optionalString (mainFunction !=null) "-e dofile(arg[0]).${mainFunction}()";
  in stdenv.mkDerivation {
    inherit name;
    src = ./.;
    nativeBuildInputs = [ fennel ];
    buildPhase = ''
      (
       echo "#!${lua}/bin/lua ${luaFlags}"
       echo "package.path = ${lib.strings.escapeShellArg (builtins.concatStringsSep "" luapath)} .. package.path"
       echo "package.cpath = ${lib.strings.escapeShellArg (builtins.concatStringsSep "" luacpath)} .. package.cpath"
       fennel ${if correlate then "--correlate" else ""} --compile ${source}
      ) >  ${name}.lua
    '';
    installPhase = ''
      cp ${name}.lua $out
      chmod +x $out
    '';
  }
