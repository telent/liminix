{
  writeFennel
, linotify
, anoia
}:
writeFennel "acquire-wan-address" {
  packages = [ linotify anoia ];
  mainFunction = "run";
} ./acquire-wan-address.fnl
