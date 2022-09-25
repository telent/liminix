{ config, pkgs, ... } :
let
  inherit (pkgs.liminix.networking) interface address pppoe;
  inherit (pkgs.liminix.services) oneshot longrun bundle target output;
in rec {
  services.loopback =
    let iface = interface { type = "loopback"; device = "lo";};
    in bundle {
      name = "loopback";
      contents = [
        (address iface { family = "inet4"; addr ="127.0.0.1";})
        (address iface { family = "inet6"; addr ="::1";})
      ];
    };

  kernel.config = {
    "PPP" = "y";
    "PPPOE" = "y";
    "PPPOL2TP" = "y";
  };

  services.pppoe =
    let iface = interface { type = "hardware"; device = "eth0"; };
    in pppoe iface {};

  services.defaultroute4 =
    let iface = services.pppoe;
    in oneshot {
      name = "defaultroute4";
      up = ''
        ip route add default gw $(cat ${output iface "address"})
        echo "1" > /sys/net/ipv4/$(cat ${output iface "ifname"})
      '';
      down = ''
        ip route del default gw $(cat ${output iface "address"})
        echo "0" > /sys/net/ipv4/$(cat ${output iface "ifname"})
      '';
      dependencies = [iface];
    };

  services.default = target {
    name = "default";
    contents = with services; [ loopback defaultroute4 ];
  };

  systemPackages = [ pkgs.hello ] ;
}
