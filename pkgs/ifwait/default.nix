{
  lua
, netlink-lua
, writeFennelScript
, runCommand
}:
runCommand "ifwait" {} ''
  mkdir -p $out/bin
  cp -p ${writeFennelScript "ifwait" [netlink-lua] ./ifwait.fnl} $out/bin/ifwait
''
