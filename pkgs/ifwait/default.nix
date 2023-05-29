{
  luaSmall
, netlink-lua
, writeFennelScript
, runCommand
}:
let
  lua = luaSmall;
  netlink = netlink-lua.override {inherit lua;};
in runCommand "ifwait" {} ''
  mkdir -p $out/bin
  cp -p ${writeFennelScript "ifwait" [netlink] ./ifwait.fnl} $out/bin/ifwait
''
