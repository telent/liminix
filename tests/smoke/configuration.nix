{ config, pkgs, ... } :
let
  inherit (pkgs.liminix.networking) interface address udhcpc odhcpc route;
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

  services.defaultroute4 = route {
    name = "defautlrote";
    via = "$(cat ${output services.dhcpv4 "address"})";
    target = "default";
    dependencies = [ services.dhcpv4 ];
  };

  services.packet_forwarding =
    let
      iface = services.dhcpv4;
      filename = "/proc/sys/net/ipv4/conf/$(cat ${output iface "ifname"})/forwarding";
    in oneshot {
      name = "let-the-ip-flow";
      up = "echo 1 > ${filename}";
      down = "echo 0 > ${filename}";
      dependencies = [iface];
    };

  services.default = target {
    name = "default";
    contents = with services; [ loopback ntp defaultroute4 ];
  };

  defaultProfile.packages = [ pkgs.hello ] ;
}
