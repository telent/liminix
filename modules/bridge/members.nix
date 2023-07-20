{
  liminix
, ifwait
, lib
}:
let
  inherit (liminix.networking) interface;
  inherit (liminix.services) bundle oneshot;
  inherit (liminix.lib) typeChecked;
  inherit (lib) mkOption types;
  t = {
    members = mkOption {
      type = types.listOf liminix.lib.types.service;
      description = "interfaces to add to the bridge";
    };
    primary = mkOption {
      type = liminix.lib.types.service;
      description = "bridge interface to add them to";
    };
  };
in
params:
let
  inherit (typeChecked "bridge-members" t params) members primary;
  addif = member :
    oneshot {
      name = "add-${member.device}-to-br-${primary.device}";
      up = "${ifwait}/bin/ifwait ${member.device} running && ip link set dev ${member.device} master ${primary.device}";
      down = "ip link set dev ${member.device} nomaster";
      dependencies = [ primary member ];
    };
in bundle {
  name = "bridge-${primary.device}-members";
  contents = map addif members;
}
