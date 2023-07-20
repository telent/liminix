{
  liminix
, lib
}:
let
  inherit (liminix.networking) interface;
  inherit (liminix.lib) typeChecked;
  inherit (lib) mkOption types;
  t = {
    ifname = mkOption {
      type = types.str;
      description = "interface name for the bridge device";
    };
  };
in
params:
let
  inherit (typeChecked "bridge" t params) ifname;
in interface {
  device = ifname;
  type = "bridge";
}
