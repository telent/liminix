{
  runCommand
, luaSmall
, runtimeShell
, lib
}:
let lua = luaSmall;
in name : packages : source :
  let
    luapath = builtins.map (f: "${f}/share/lua/${lua.luaversion}/?.lua;") packages;
    luacpath = builtins.map (f: "${f}/lib/lua/${lua.luaversion}/?.so;") packages;
    in runCommand name {} ''
      #!${runtimeShell}
      (
      echo "#!${lua}/bin/lua"
      echo "package.path = ${lib.strings.escapeShellArg luapath} .. package.path"
      echo "package.cpath = ${lib.strings.escapeShellArg luacpath} .. package.cpath"
      ${lua.pkgs.fennel}/bin/fennel --correlate --compile ${source}
      ) > $out
      chmod a+x $out
    ''
