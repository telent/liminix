{
  writeFennel
, linotify
, anoia
, lua
}:
writeFennel "acquire-wan-address" {
  packages = [ linotify anoia lua.pkgs.luafilesystem ];
  mainFunction = "run";
} ./acquire-wan-address.fnl
