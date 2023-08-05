{
  liminix
, lib
}:
{ ifname } :
let
  inherit (liminix.networking) interface;
  inherit (liminix.lib) typeChecked;
  inherit (lib) mkOption types;
in interface {
  device = ifname;
  type = "bridge";
}
