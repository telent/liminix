{
  liminix
, lib
, callPackage
}:
{ client, interface } :
let
  inherit (liminix.services) longrun;
  inherit (lib) mkOption types;
  name = "dhcp6c.addr.${client.name}.${interface.name}";
  script = callPackage ./acquire-wan-address.nix {  };
in longrun {
  inherit name;
  run = "${script} $SERVICE_OUTPUTS/${client.name} $(output ${interface} ifname)";
  dependencies = [ client interface ];
}
