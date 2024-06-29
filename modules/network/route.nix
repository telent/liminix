{
  liminix
, lib
}:
{ target, via, interface ? null, metric }:
let
  inherit (liminix.services) oneshot;
  with_dev = if interface != null then "dev $(output ${interface} ifname)" else "";
  target_hash = builtins.substring 0 12 (builtins.hashString "sha256" target);
  via_hash = builtins.substring 0 12 (builtins.hashString "sha256" via);
in oneshot {
  name = "route-${target_hash}-${builtins.substring 0 12 (builtins.hashString "sha256" "${via_hash}-${if interface!=null then interface.name else ""}")}";
  up = ''
    ip route add ${target} via ${via} metric ${toString metric} ${with_dev}
  '';
  down = ''
    ip route del ${target} via ${via} ${with_dev}
  '';
  dependencies = [] ++ lib.optional (interface != null) interface;
}
