{
  liminix
, ifwait
, lib
}:
{ members, ifname } :
let
  inherit (liminix.networking) interface;
  inherit (liminix.services) bundle oneshot;
  inherit (lib) mkOption types;
  primary = interface {
    device = ifname;
    type = "bridge";
  };
  addif = member :
    let ifname = "$(output ${member} ifname)";
    in oneshot {
      name = "add-${member.name}-to-br-${primary.name}";
      up = "${ifwait}/bin/ifwait ${ifname} running && ip link set dev ${ifname} master $(output ${primary} ifname)";
      down = "ip link set dev ${ifname} nomaster";
      dependencies = [ primary member ];
    };

in bundle {
  name = "bridge-${primary.name}-members";
  contents = [ primary ] ++ map addif members;
}
