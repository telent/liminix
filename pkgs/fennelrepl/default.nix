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
      lua.pkgs.luafilesystem
    ];
    join = ps: builtins.concatStringsSep ";" ps;
    luapath = join (builtins.map (f:
      "${f}/share/lua/${lua.luaversion}/?.lua;" +
      "${f}/share/lua/${lua.luaversion}/?/init.lua"
    ) packages);
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
    if #arg > 0 then
       script = table.remove(arg, 1)
       fennel.dofile(script, {},  arg)
    else
        fennel.repl()
    end
  ''
