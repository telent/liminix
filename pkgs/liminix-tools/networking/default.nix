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
  inherit ifup;

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
