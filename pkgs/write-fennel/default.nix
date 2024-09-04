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
  inherit (builtins) concatStringsSep map;
  luapath = map (
    f: "${f}/share/lua/${lua.luaversion}/?.lua;" + "${f}/share/lua/${lua.luaversion}/?/init.lua;"
  ) packages;
  luacpath = map (f: "${f}/lib/lua/${lua.luaversion}/?.so;") packages;
  macropath = concatStringsSep ";"
    (map (f: "${f}/share/lua/${lua.luaversion}/?.fnl") macros);
  luaFlags = lib.optionalString (mainFunction != null) "-e dofile(arg[0]).${mainFunction}()";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;
  nativeBuildInputs = [ fennel ];
  buildPhase = ''
    (
     echo "#!${lua}/bin/lua ${luaFlags}"
     echo "package.path = ${lib.strings.escapeShellArg (concatStringsSep "" luapath)} .. package.path"
     echo "package.cpath = ${lib.strings.escapeShellArg (concatStringsSep "" luacpath)} .. package.cpath"
     echo "local ok, ll = pcall(require,'lualinux'); if ok then ll.setenv('PATH',${lib.escapeShellArg (lib.makeBinPath packages)} .. \":\" .. os.getenv('PATH')) end"
     fennel ${if macropath != "" then "--add-macro-path ${lib.strings.escapeShellArg macropath}" else ""}  ${if correlate then "--correlate" else ""} --compile ${source} 
    ) >  ${name}.lua

  '';
  installPhase = ''
    cp ${name}.lua $out
    chmod +x $out
  '';
}
