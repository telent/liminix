{ config, tools, pkgs } :
let
  inherit (tools.networking) interface address udhcpc odhcpc;
  inherit (tools.services) oneshot longrun bundle output;
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
    run = let s = services;
              r =  "${pkgs.ntp}/bin/ntp $(cat ${output s.dhcpv4 "ntp_servers"}) $(cat ${output s.dhcpv6 "NTP_IP"})";
          in (builtins.trace r r);
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
    let s = services;
    in oneshot {
      name = "defaultroute4";
      up = ''
        ip route add default gw $(cat ${output s.dhcpv4 "address"})
        echo "1" > /sys/net/ipv4/$(cat ${output s.dhcpv4 "ifname"})
      '';
      down = ''
        ip route del default gw $(cat ${output s.dhcpv4 "address"})
        echo "0" > /sys/net/ipv4/$(cat ${output s.dhcpv4 "ifname"})
      '';
    };
  systemPackages = [ pkgs.hello ] ;
}
