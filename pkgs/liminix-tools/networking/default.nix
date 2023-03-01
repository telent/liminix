{
  callPackage
, liminix
, ifwait
, lib
}:
let
  inherit (liminix.services) oneshot longrun;
  inherit (lib) concatStringsSep optional;
in {
  interface = { type ? "hardware", device, primary ? null, dependencies ? [] }  @ args:
    let ups =
          []
          ++ optional (type == "bridge")
            "ip link add name ${device} type bridge"
          ++ ["${ifwait}/bin/ifwait -v ${device} present"]
          ++ ["ip link set up dev ${device}"]
          ++ optional (primary != null)
            "ip link set dev ${device} master ${primary.device}";
    in oneshot {
      name = "${device}.link";
      up = lib.concatStringsSep "\n" ups;
      down = "ip link set down dev ${device}";
      dependencies = dependencies ++ lib.optional (primary != null) primary;
    } // {
      inherit device;
    };
  address = interface: { family, dependencies ? [], prefixLength, address } @ args:
    let inherit (builtins) toString;
    in oneshot {
      dependencies = [ interface ] ++ dependencies;
      name = "${interface.device}.addr.${address}";
      up = "ip address add ${address}/${toString prefixLength} dev ${interface.device} ";
      down = "ip address del ${address}/${toString prefixLength} dev ${interface.device} ";
    } // {
      inherit (interface) device;
    };
  udhcpc = callPackage ./udhcpc.nix {};
  odhcpc = interface: { ... } @ args: longrun {
    name = "${interface.device}.odhcp";
    run = "odhcpcd ${interface.device}";
  };
  pppoe = callPackage ./pppoe.nix {};
  dnsmasq = callPackage ./dnsmasq.nix {};
  hostapd = callPackage ./hostapd.nix {};
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
