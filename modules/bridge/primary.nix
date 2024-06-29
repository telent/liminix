{
  liminix
, lib
}:
{ ifname } :
let
  inherit (liminix.services) oneshot;
in oneshot rec {
  name = "${ifname}.link";
  up = ''
    ip link add name ${ifname} type bridge
    ${liminix.networking.ifup name ifname}
  '';
  down = "ip link set down dev ${ifname}";
}
