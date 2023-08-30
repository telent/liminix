{
  liminix
, lib
}:
{ ifname, primary, vid } :
let
  inherit (liminix.services) oneshot;
in oneshot rec {
  name = "${ifname}.link";
  up = ''
    ip link add link $(output ${primary} ifname) name ${ifname} type vlan id ${vid}
    ${liminix.networking.ifup name ifname}
  '';
  down = "ip link set down dev ${ifname}";
}
