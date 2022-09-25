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
        (address iface { family = "inet4"; address ="127.0.0.1"; prefixLength = 8;})
        (address iface { family = "inet6"; address ="::1"; prefixLength = 128;})
      ];
    };

  kernel.config = {
    "IKCONFIG_PROC" = "y";
    "PPP" = "y";
    "PPPOE" = "y";
    "PPPOL2TP" = "y";
    "PPP_ASYNC" = "y";
    "PPP_BSDCOMP" = "y";
    "PPP_DEFLATE" = "y";
    "PPP_MPPE" = "y";
    "PPP_SYNC_TTY" = "y";
  };

  services.syslogd = longrun {
    name = "syslogd";
    run = "${pkgs.busybox}/bin/syslogd -n -O /run/syslog";
  };

  services.pppoe =
    let iface = interface { type = "hardware"; device = "eth0"; };
    in pppoe iface {
      ppp-options = [
        "debug" "+ipv6" "noauth"
        "name" "db123@a.1"
        "password" "NotReallyTheSecret"
      ];
    };

  services.defaultroute4 =
    let iface = services.pppoe;
    in oneshot {
      name = "defaultroute4";
      up = ''
        ip route add default via $(cat ${output iface "address"})
        echo "1" > /proc/sys/net/ipv4/conf/$(cat ${output iface "ifname"}/forwarding)
      '';
      down = ''
        ip route del default via $(cat ${output iface "address"})
        echo "0" > /proc/sys/net/ipv4/conf/$(cat ${output iface "ifname"}/forwarding)
      '';
      dependencies = [iface];
    };

  services.default = target {
    name = "default";
    contents = with services; [ loopback defaultroute4 syslogd ];
  };

  systemPackages = [ pkgs.hello ] ;
}
