{
  netlink-lua,
  writeFennel,
  runCommand,
  anoia,
  lualinux,
  s6-rc-up-tree,
}:
runCommand "ifwait" { } ''
  mkdir -p $out/bin
  cp -p ${
    writeFennel "ifwait" {
      packages = [
        anoia
        lualinux
        netlink-lua
        s6-rc-up-tree
      ];
    } ./ifwait.fnl
  } $out/bin/ifwait
''
