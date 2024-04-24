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
, netlink-lua
, fennel
}:
let packages = [
      linotify
      anoia
      fennel
      netlink-lua
      lua.pkgs.readline
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
    table.insert(package.loaders or package.searchers,1, fennel.searcher)
    fennel['macro-path'] = "${anoia.dev}/share/lua/${lua.luaversion}/?.fnl;" .. fennel['macro-path']

    local more_fennel = os.getenv("FENNEL_PATH")
    if more_fennel then
        fennel.path = more_fennel .. ";" .. fennel.path
    end
    if #arg > 0 then
       script = table.remove(arg, 1)
       fennel.dofile(script, {correlate = true},  arg)
    else
        fennel.repl()
    end
  ''
