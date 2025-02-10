{
  lua,
  lib,
  fennel,
  stdenv,
}:
name:
{
  packages ? [ ],
  macros ? [ ],
  correlate ? false,
  mainFunction ? null,
}:
source:
let
  inherit (builtins) concatStringsSep replaceStrings map;
  luapath = map (
    f: "${f}/share/lua/${lua.luaversion}/?.lua;" + "${f}/share/lua/${lua.luaversion}/?/init.lua;"
  ) packages;
  luacpath = map (f: "${f}/lib/lua/${lua.luaversion}/?.so;") packages;
  macropath = concatStringsSep ";" (map (f: "${f}/share/lua/${lua.luaversion}/?.fnl") macros);
  luaFlags = lib.optionalString (mainFunction != null) "-e dofile(arg[0]).${mainFunction}()";
  quoteString = string: "'${replaceStrings [ "'" ] [ "'\\''" ] string}'";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;
  nativeBuildInputs = [ fennel ];
  buildPhase = ''
    (
     echo "#!${lua}/bin/lua ${luaFlags}"
     echo "package.path = ${quoteString (concatStringsSep "" luapath)} .. package.path"
     echo "package.cpath = ${quoteString (concatStringsSep "" luacpath)} .. package.cpath"
     echo "local ok, stdlib = pcall(require,'posix.stdlib'); if ok then stdlib.setenv('PATH',${quoteString (lib.makeBinPath packages)} .. \":\" .. os.getenv('PATH')) end"
     echo "local ok, ll = pcall(require,'lualinux'); if ok then ll.setenv('PATH',${quoteString (lib.makeBinPath packages)} .. \":\" .. os.getenv('PATH')) end"
     fennel ${if macropath != "" then "--add-macro-path ${quoteString macropath}" else ""}  ${
       if correlate then "--correlate" else ""
     } --compile ${source} 
    ) >  ${name}.lua

  '';
  installPhase = ''
    cp ${name}.lua $out
    chmod +x $out
  '';
}
