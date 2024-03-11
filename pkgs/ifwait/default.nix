{
  lua
, netlink-lua
, writeFennelScript
, runCommand
, anoia
}:
runCommand "ifwait" {} ''
  mkdir -p $out/bin
  cp -p ${writeFennelScript "ifwait" [anoia netlink-lua] ./ifwait.fnl} $out/bin/ifwait
''
