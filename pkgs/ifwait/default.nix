{
  netlink-lua,
  writeFennel,
  runCommand,
  anoia,
}:
runCommand "ifwait" { } ''
  mkdir -p $out/bin
  cp -p ${
    writeFennel "ifwait" {
      packages = [
        anoia
        netlink-lua
      ];
    } ./ifwait.fnl
  } $out/bin/ifwait
''
