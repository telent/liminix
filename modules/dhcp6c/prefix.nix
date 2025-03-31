{
  liminix,
  callPackage,
}:
{ client, interface }:
let
  inherit (liminix.services) longrun;
  name = "dhcp6c.prefix.${client.name}.${interface.name}";
  script = callPackage ./acquire-delegated-prefix.nix { };
in
longrun {
  inherit name;
  run = "${script} ${client} $(output ${interface} ifname)";
  dependencies = [
    client
    interface
  ];
}
