{
  writeFennel
, linotify
, anoia
, lua
}:
writeFennel "acquire-delegated-prefix" {
  packages = [ linotify anoia lua.pkgs.luafilesystem ];
  mainFunction = "run";
} ./acquire-delegated-prefix.fnl
