{
  callPackage
, liminix
, ifwait
, lib
, serviceFns
}:
let
  inherit (liminix.services) oneshot longrun;
  inherit (lib) concatStringsSep optional;
  ifup = name : ifname : ''
    . ${serviceFns}
    ${ifwait}/bin/ifwait -v ${ifname} present
    ip link set up dev ${ifname}
    (in_outputs ${name}
     echo ${ifname} > ifname
    )
  '';

in {
  interface = { type ? "hardware", device, link ? null, primary ? null, id ? null, dependencies ? [] }  @ args:
    let name = "${device}.link";
        ups =
          []
          ++ optional (type == "bridge")
            "ip link add name ${device} type bridge"
          ++ optional (type == "vlan")
            "ip link add link ${link} name ${device} type vlan id ${id}"
          ++ [(ifup name device)]
          ++ optional (primary != null)
            "ip link set dev ${device} master ${primary.device}";
    in oneshot {
      inherit name;
      up = lib.concatStringsSep "\n" ups;
      down = "ip link set down dev ${device}";
      dependencies = dependencies ++ lib.optional (primary != null) primary;
    };
  inherit ifup;
  address = interface: { family, dependencies ? [], prefixLength, address } @ args:
    let inherit (builtins) toString;
    in oneshot {
      dependencies = [ interface ] ++ dependencies;
      name = "${interface.name}.addr.${address}";
      up = "ip address add ${address}/${toString prefixLength} dev $(output ${interface} ifname)";
      down = "ip address del ${address}/${toString prefixLength} dev $(output ${interface} ifname)";
    };
  route = { name, target, via, dependencies, dev ? null }:
    let with_dev = if dev != null then "dev ${dev}" else "";
    in oneshot {
      inherit name;
      up = ''
        ip route add ${target} via ${via} ${with_dev}
      '';
      down = ''
        ip route del ${target} via ${via} ${with_dev}
      '';
      inherit dependencies;
    };
}
