{
  liminix
, ifwait
, lib
}:
{ members, primary } :
let
  inherit (liminix.networking) interface;
  inherit (liminix.services) bundle oneshot;
  inherit (lib) mkOption types;
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
