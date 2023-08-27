{
  liminix
, ifwait
, lib
}:
{ ifname } :
let
  inherit (liminix.networking) interface;
  inherit (liminix.services) bundle oneshot;
  inherit (lib) mkOption types;
in oneshot rec {
  name = "${ifname}.link";
  up = ''
    ip link add name ${ifname} type bridge
    ${liminix.networking.ifup name ifname}
  '';
  down = "ip link set down dev ${ifname}";
}
