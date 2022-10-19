{ config, pkgs, lib, ... } :
let
  inherit (pkgs.liminix.networking) interface address pppoe route dnsmasq;
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

  services.lan4 =
    let iface = interface { type = "hardware"; device = "eth1";};
    in address iface { family = "inet4"; address ="192.168.19.1"; prefixLength = 24;};

  kernel.config = {
    "PPP" = "y";
    "PPPOE" = "y";
    "PPPOL2TP" = "y";
    "L2TP" = "y";
    "PPP_ASYNC" = "y";
    "PPP_BSDCOMP" = "y";
    "PPP_DEFLATE" = "y";
    "PPP_MPPE" = "y";
    "PPP_SYNC_TTY" = "y";
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

  services.defaultroute4 = route {
    name = "defautlrote";
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

  users.dnsmasq = {
    uid = 51; gid= 51; gecos = "DNS/DHCP service user";
    dir = "/run/dnsmasq";
    shell = "/bin/false";
  };
  groups.dnsmasq = {
    gid = 51; usernames = ["dnsmasq"];
  };
  services.dns =
    dnsmasq {
      interface = services.lan4;
      ranges = ["192.168.19.10,192.168.19.253"];
      domain = "fake.liminix.org";
    };

  services.default = target {
    name = "default";
    contents = with services; [
      loopback
      defaultroute4
      packet_forwarding
      dns
    ];
  };
  defaultProfile.packages = [ pkgs.hello ] ;
}
