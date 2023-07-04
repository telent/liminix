{
  runCommand
, runtimeShell
, fetchurl
, lib
, luaPackages
, lua
, writeScriptBin
, linotify
, anoia
, fennel
}:
let packages = [
      linotify
      anoia
      fennel
    ];
    join = ps: builtins.concatStringsSep ";" ps;
    luapath = join (builtins.map (f: "${f}/share/lua/${lua.luaversion}/?.lua") packages);
    luacpath = join (builtins.map (f: "${f}/lib/lua/${lua.luaversion}/?.so") packages);

in writeScriptBin "fennelrepl" ''
    #!${lua}/bin/lua
    package.path = ${lib.strings.escapeShellArg luapath} .. ";" .. package.path
    package.cpath = ${lib.strings.escapeShellArg luacpath} .. ";" .. (package.cpath or "")
    local fennel = require "fennel"
    fennel.install()
    local more_fennel = os.getenv("FENNEL_PATH")
    if more_fennel then
        fennel.path = more_fennel .. ";" .. fennel.path
    end
    print("path", fennel.path)
    fennel.repl()
  ''
