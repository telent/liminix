{
  writeFennelScript
, luaSmall
, linotify
}:
writeFennelScript "acquire-delegated-prefix"
  [
    (linotify.override { lua = luaSmall; })
  ]
  ./acquire-delegated-prefix.fnl
