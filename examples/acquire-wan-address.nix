{
  writeFennelScript
, linotify
, anoia
}:
writeFennelScript "acquire-wan-address"
  [ linotify anoia ]
  ./acquire-wan-address.fnl
