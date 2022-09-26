{
  callPackage
, liminix
}:
let inherit (liminix.services) oneshot longrun;
in {
  interface = { type, device }  @ args: oneshot {
    name = "${device}.link";
    up = "ip link set up dev ${device}";
    down = "ip link set down dev ${device}";
  } // {
    inherit device;
  };
  address = interface: { family, prefixLength, address } @ args:
    let inherit (builtins) toString;
    in oneshot {
      dependencies = [ interface ];
      name = "${interface.device}.addr.${address}";
      up = "ip address add ${address}/${toString prefixLength} dev ${interface.device} ";
      down = "ip address del ${address}/${toString prefixLength} dev ${interface.device} ";
    };
  udhcpc = callPackage ./udhcpc.nix {};
  odhcpc = interface: { ... } @ args: longrun {
    name = "${interface.device}.odhcp";
    run = "odhcpcd ${interface.device}";
  };
  pppoe = callPackage ./pppoe.nix {};
  route = { name, target, via, dependencies }:
    oneshot {
      inherit name;
      up = ''
        ip route add ${target} via ${via}
      '';
      down = ''
        ip route del ${target} via ${via}
      '';
      inherit dependencies;
    };
}
