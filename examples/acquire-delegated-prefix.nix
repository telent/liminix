{
  writeFennelScript
, linotify
}:
writeFennelScript "acquire-delegated-prefix"
  [ linotify ]
  ./acquire-delegated-prefix.fnl
