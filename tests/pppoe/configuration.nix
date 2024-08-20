{ config, pkgs, ... } :
let
  inherit (pkgs.liminix.services) target;
  svc = config.system.service;
in rec {
  services.lan4 = svc.network.address.build {
    interface = config.hardware.networkInterfaces.lan;
    family = "inet"; address ="192.168.19.1"; prefixLength = 24;
  };

  imports = [
    ../../modules/ppp
    ../../modules/dnsmasq
    ../../modules/network
  ];

  services.pppoe =
    svc.pppoe.build {
      interface = config.hardware.networkInterfaces.wan;
      username = "db123@a.1";
      password= "NotReallyTheSecret";
    };

  services.defaultroute4 = svc.network.route.build {
    via = "$(output ${services.pppoe} address)";
    target = "default";
    dependencies = [ services.pppoe ];
  };

  services.packet_forwarding = svc.network.forward.build {
    dependencies = [services.pppoe];
  };

  services.dns =
    svc.dnsmasq.build {
      interface = services.lan4;
      ranges = ["192.168.19.10,192.168.19.253"];
      domain = "fake.liminix.org";
    };

  defaultProfile.packages = [ pkgs.hello ] ;
}
