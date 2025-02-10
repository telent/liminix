{
  writeFennel,
  anoia,
  lualinux,
}:
writeFennel "odhcpc-script" {
  packages = [
    anoia
    lualinux
  ];
} ./odhcp6-script.fnl
