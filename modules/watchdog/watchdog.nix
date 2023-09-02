{
  liminix
, lib
}:
{ watched, headStart } :
let
  inherit (liminix.services) longrun;
in longrun {
  name = "watchdog";
  run =
    "HEADSTART=${toString headStart} ${./gaspode.sh} ${lib.concatStringsSep " " (builtins.map (s: s.name) watched)}";
}
