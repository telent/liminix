{
  runCommand
, luaSmall
, runtimeShell
, fetchurl
, lib
, lua53Packages
}:
let inherit (lua53Packages) lua;
in name : packages : source :
  let
    fennel = fetchurl {
      url = "https://fennel-lang.org/downloads/fennel-1.3.0";
      hash = "sha256-hYSD3rBYF8iTjBOA1m+TvUu8BSp8q6uIMUXi0xwo/dU=";
    };

    luapath = builtins.map (f: "${f}/share/lua/${luaSmall.luaversion}/?.lua;") packages;
    luacpath = builtins.map (f: "${f}/lib/lua/${luaSmall.luaversion}/?.so;") packages;
  in runCommand name {
    nativeBuildInputs =  [ lua ];
  } ''
     echo $PATH
      #!${runtimeShell}
      (
      echo "#!${luaSmall}/bin/lua"
      echo "package.path = ${lib.strings.escapeShellArg luapath} .. package.path"
      echo "package.cpath = ${lib.strings.escapeShellArg luacpath} .. package.cpath"
      lua ${fennel} --correlate --compile ${source}
      ) > $out
      chmod a+x $out
    ''
