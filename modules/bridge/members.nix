{
  liminix,
  ifwait,
  svc,
}:
{ members, primary }:

let
  inherit (liminix.networking) interface;
  inherit (liminix.services) bundle oneshot;
  addif =
    member:
    # how do we get sight of services from here? maybe we need to
    # implement ifwait as a regular derivation instead of a
    # service definition
    svc.ifwait.build {
      state = "running";
      interface = member;
      dependencies = [
        primary
        member
      ];
      service = oneshot {
        name = "${primary.name}.member.${member.name}";
        up = ''
          ip link set dev $(output ${member} ifname) master $(output ${primary} ifname)
          ip -6 route flush dev $(output ${member} ifname)
        '';
        down = "ip link set dev $(output ${member} ifname) nomaster";
      };
    };
in
bundle {
  name = "${primary.name}.members";
  contents = map addif members;
}
