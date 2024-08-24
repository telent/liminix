{ lib
, lua
, lualinux
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
      lualinux
      netlink-lua
      lua.pkgs.readline
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
    local specials = require("fennel.specials")
    table.insert(package.loaders or package.searchers,1, fennel.searcher)
    fennel['macro-path'] = "${anoia.dev}/share/lua/${lua.luaversion}/?.fnl;" .. fennel['macro-path']

    local function eval_as_test(f)
      local g = (specials["make-compiler-env"]())._G
      g["RUNNING_TESTS"] = true
      return fennel.dofile(f, {correlate = true, compilerEnv = g})
    end

    local more_fennel = os.getenv("FENNEL_PATH")
    if more_fennel then
      fennel.path = more_fennel .. ";" .. fennel.path
    end
    if #arg > 0 then
      if arg[1] == '--test' then
        eval_as_test(arg[2])
      else
        script = table.remove(arg, 1)
        fennel.dofile(script, {correlate = true},  arg)
      end
    else
      fennel.repl()
    end
  ''
