{
  liminix
, ifwait
, serviceFns
, lib
}:
{ target, via, interface ? null, metric }:
let
  inherit (liminix.services) oneshot;
  with_dev = if interface != null then "dev $(input ${interface} ifname)" else "";
in oneshot {
  name = "route-${target}-${builtins.substring 0 12 (builtins.hashString "sha256" "${via}-${if interface!=null then interface.name else ""}")}";
  up = ''
    ip route add ${target} via ${via} metric ${toString metric} ${with_dev}
  '';
  down = ''
    ip route del ${target} via ${via} ${with_dev}
  '';
  dependencies = [] ++ lib.optional (interface != null) interface;
}
