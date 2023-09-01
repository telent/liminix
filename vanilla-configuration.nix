{ config, pkgs, ... } :
let
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit (pkgs) writeText;
  svc = config.system.service;
in rec {
  imports = [
    ./modules/tftpboot.nix
    ./modules/wlan.nix
    ./modules/network
    ./modules/ntp
    ./modules/vlan
  ];

  services.dhcpv4 =
    let iface = svc.network.link.build { ifname = "eth1"; };
    in svc.network.dhcp.client.build { interface = iface; };

  services.defaultroute4 = svc.network.route.build {
    via = "$(output ${services.dhcpv4} address)";
    target = "default";
    dependencies = [ services.dhcpv4 ];
  };

  services.packet_forwarding = svc.network.forward.build { };

  services.ntp = config.system.service.ntp.build {
    pools = { "pool.ntp.org" = ["iburst"] ; };
  };

  boot.tftp = {
    serverip = "192.168.8.148";
    ipaddr = "192.168.8.251";
  };

  defaultProfile.packages = [ pkgs.hello ] ;
}
