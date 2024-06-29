{
  liminix
, lib
}:
{ enableIPv4, enableIPv6 }:
let
  inherit (liminix.services) oneshot;
  ip4 = "/proc/sys/net/ipv4/conf/all/forwarding";
  ip6 = "/proc/sys/net/ipv6/conf/all/forwarding";
  opt = lib.optionalString;
  sysctls = b :
    ""
    + opt enableIPv4 "echo ${b} > ${ip4}\n"
    + opt enableIPv6 "echo ${b} > ${ip6}\n";
in oneshot {
  name = "forwarding${opt enableIPv4 "4"}${opt enableIPv6 "6"}";
  up = sysctls "1";
  down = sysctls "0";
}
