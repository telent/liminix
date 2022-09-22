{ config, pkgs } :
let
  inherit (pkgs.liminix.networking) interface address udhcpc odhcpc;
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
  services.dhcpv4 =
    let iface = interface { type = "hardware"; device = "eth0"; };
    in udhcpc iface {};

  services.dhcpv6 =
    let iface = interface { type = "hardware"; device = "eth0"; };
    in odhcpc iface { uid = "e7"; };

  services.ntp = longrun {
    # the simplest approach at the consumer end  is to require the
    # producer to create a file per output variable.
    name = "ntp";
    run = let inherit (services) dhcpv4 dhcpv6;
          in "${pkgs.ntp}/bin/ntpd $(cat ${output dhcpv4 "ntp_servers"}) $(cat ${output dhcpv6 "NTP_IP"})";

    # I don't think it's possible to standardise the file names
    # generally, as different services have different outputs, but it
    # would be cool if services that provide an interface could use
    # the same name as each other. e.g. for anything implementing
    # addressProvider you might expect (output svc "address") or
    # (output svc "family") to work. Otherwise switching a network link
    # from static to dhcp might require reviewing all the downstreams
    # that refer to it.
    # Also, services should declare the outputs they provide
    outputs = [];
    dependencies = [services.dhcpv4];
  };

  services.defaultroute4 =
    let inherit (services) dhcpv4;
    in oneshot {
      name = "defaultroute4";
      up = ''
        ip route add default gw $(cat ${output dhcpv4 "address"})
        echo "1" > /sys/net/ipv4/$(cat ${output dhcpv4 "ifname"})
      '';
      down = ''
        ip route del default gw $(cat ${output dhcpv4 "address"})
        echo "0" > /sys/net/ipv4/$(cat ${output dhcpv4 "ifname"})
      '';
    };

  services.default = target {
    name = "default";
    contents = with services; [ loopback ntp defaultroute4 ];
  };

  systemPackages = [ pkgs.hello ] ;
}
