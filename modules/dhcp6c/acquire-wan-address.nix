{
  writeFennel,
  linotify,
  anoia,
  lualinux,
}:
writeFennel "acquire-wan-address" {
  packages = [
    linotify
    anoia
    lualinux
  ];
  mainFunction = "run";
} ./acquire-wan-address.fnl
