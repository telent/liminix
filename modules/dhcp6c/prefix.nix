{
  liminix
, lib
, callPackage
}:
{ client, interface } :
let
  inherit (liminix.services) longrun;
  inherit (lib) mkOption types;
  name = "dhcp6c.prefix.${client.name}.${interface.name}";
  script = callPackage ./acquire-delegated-prefix.nix {  };
in longrun {
  inherit name;
  run = "${script} /run/service-state/${client.name} $(output ${interface} ifname)";
  dependencies = [ client interface ];
}
