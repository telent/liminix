{
  writeFennelScript
, anoia
, lua
}:
writeFennelScript  "odhcpc-script" [anoia lua.pkgs.luafilesystem] ./odhcp6-script.fnl
