{ config, pkgs, ... } :
let
  inherit (pkgs.liminix.networking) interface address udhcpc odhcpc route;
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
in rec {
  imports = [
    ./modules/tftpboot.nix
    ./modules/wlan.nix
  ];
  services.loopback = config.hardware.networkInterfaces.lo;

  services.dhcpv4 =
    let iface = interface { type = "hardware"; device = "eth0"; };
    in udhcpc iface {};

  services.dhcpv6 =
    let iface = interface { type = "hardware"; device = "eth0"; };
    in odhcpc iface { uid = "e7"; };

  services.ntp = longrun {
    name = "ntp";
    run = let inherit (services) dhcpv4 dhcpv6;
          in "${pkgs.ntp}/bin/ntpd $(output ${dhcpv4} ntp_servers) $(output ${dhcpv6} NTP_IP})";

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
    via = "$(output ${services.dhcpv4} address)";
    target = "default";
    dependencies = [ services.dhcpv4 ];
  };

  services.packet_forwarding =
    let
      iface = services.dhcpv4;
      filename = "/proc/sys/net/ipv4/conf/$(output ${iface} ifname)/forwarding";
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

  boot.tftp = {
    serverip = "192.168.8.148";
    ipaddr = "192.168.8.251";
  };

  defaultProfile.packages = [ pkgs.hello ] ;
}
