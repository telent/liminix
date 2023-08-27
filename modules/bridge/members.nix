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
      name = "${primary.name}.member.${member.name}";
      up = ''
        dev=$(output ${member} ifname)
        ${ifwait}/bin/ifwait $dev running && ip link set dev $dev master $(output ${primary} ifname)
      '';
      down = "ip link set dev $(output ${member} ifname) nomaster";
      dependencies = [ primary member ];
    };
in bundle {
  name = "${primary.name}.members";
  contents = map addif members;
}
