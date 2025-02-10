{
  writeFennel,
  linotify,
  anoia,
  lualinux,
}:
writeFennel "acquire-delegated-prefix" {
  packages = [
    linotify
    anoia
    lualinux
  ];
  mainFunction = "run";
} ./acquire-delegated-prefix.fnl
