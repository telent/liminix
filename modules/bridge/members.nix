{
  liminix
, ifwait
, lib
, svc
}:
{ members, primary } :

let
  inherit (liminix.networking) interface;
  inherit (liminix.services) bundle oneshot;
  inherit (lib) mkOption types;
  addif = member :
    # how do we get sight of services from here? maybe we need to
    # implement ifwait as a regualr derivation instead of a
    # servicedefinition
    svc.ifwait.build {
      state = "running";
      interface = member;
      dependencies = [ primary member ];
      service = oneshot {
        name = "${primary.name}.member.${member.name}";
        up = ''
          ip link set dev $(output ${member} ifname) master $(output ${primary} ifname)
        '';
        down = "ip link set dev $(output ${member} ifname) nomaster";
      };
    };
in bundle {
  name = "${primary.name}.members";
  contents = map addif members;
}
