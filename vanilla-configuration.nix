{ config, pkgs, ... } :
let
  inherit (pkgs.liminix.networking) interface address route;
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit (pkgs) writeText;
  svc = config.system.service;
in rec {
  imports = [
    ./modules/tftpboot.nix
    ./modules/wlan.nix
    ./modules/network
    ./modules/ntp
  ];
  services.loopback = config.hardware.networkInterfaces.lo;

  services.dhcpv4 =
    let iface = svc.network.link.build { ifname = "eth1"; };
    in svc.network.dhcp.client.build { interface = iface; };

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

  services.ntp = config.system.service.ntp.build {
    pools = { "pool.ntp.org" = ["iburst"] ; };
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
