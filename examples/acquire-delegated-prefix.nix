{
  writeFennelScript
, linotify
, anoia
}:
writeFennelScript "acquire-delegated-prefix"
  [ linotify anoia ]
  ./acquire-delegated-prefix.fnl
