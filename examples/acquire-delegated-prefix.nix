{
  writeFennelScript
, linotify
, anoia
, lua
}:
writeFennelScript "acquire-delegated-prefix"
  [ linotify anoia lua.pkgs.luafilesystem ]
  ./acquire-delegated-prefix.fnl
