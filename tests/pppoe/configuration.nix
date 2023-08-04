{ config, pkgs, lib, ... } :
let
  inherit (pkgs.liminix.networking) interface address route;
  inherit (pkgs.liminix.services) oneshot longrun bundle target output;
in rec {
  services.lan4 =
    let iface = interface { type = "hardware"; device = "eth1";};
    in address iface { family = "inet4"; address ="192.168.19.1"; prefixLength = 24;};

  imports = [
    ../../modules/ppp
    ../../modules/dnsmasq
  ];

  services.pppoe =
    config.system.service.pppoe {
      interface = interface { type = "hardware"; device = "eth0"; };
      ppp-options = [
        "debug" "+ipv6" "noauth"
        "name" "db123@a.1"
        "password" "NotReallyTheSecret"
      ];
    };

  services.defaultroute4 = route {
    name = "defaultroute";
    via = "$(output ${services.pppoe} address)";
    target = "default";
    dependencies = [ services.pppoe ];
  };

  services.packet_forwarding =
    let
      iface = services.pppoe;
      filename = "/proc/sys/net/ipv4/conf/$(output ${iface} ifname)/forwarding";
    in oneshot {
      name = "let-the-ip-flow";
      up = "echo 1 > ${filename}";
      down = "echo 0 > ${filename}";
      dependencies = [iface];
    };

  services.dns =
    config.system.service.dnsmasq.build {
      interface = services.lan4;
      ranges = ["192.168.19.10,192.168.19.253"];
      domain = "fake.liminix.org";
    };

  services.default = target {
    name = "default";
    contents = with services; [
      config.hardware.networkInterfaces.lo
      defaultroute4
      packet_forwarding
      dns
    ];
  };
  defaultProfile.packages = [ pkgs.hello ] ;
}
