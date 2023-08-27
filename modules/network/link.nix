{
  liminix
, ifwait
, serviceFns
, lib
}:
{ifname, mtu} :
let
  inherit (liminix.services) longrun oneshot;
  inherit (lib) concatStringsSep;
  name = "${ifname}.link";
  up = liminix.networking.ifup name ifname;
in oneshot {
  inherit name up;
  down = "ip link set down dev ${ifname}";
}
