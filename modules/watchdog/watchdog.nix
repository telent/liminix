{
  liminix
, lib
, s6
}:
{ watched, headStart } :
let
  inherit (liminix.services) longrun;
in longrun {
  name = "watchdog";
  run =
    "PATH=${s6}/bin:$PATH HEADSTART=${toString headStart} ${./gaspode.sh} ${lib.concatStringsSep " " (builtins.map (s: s.name) watched)}";
}
