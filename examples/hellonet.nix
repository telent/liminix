{ config, pkgs, lib, ... } :
let
  inherit (pkgs) serviceFns;
  svc = config.system.service;

in rec {
  imports = [
    ../modules/network
    ../modules/dnsmasq
    ../modules/ntp
    ../modules/ssh
  ];
  hostname = "hellonet";

  services.int = svc.network.address.build {
    interface = config.hardware.networkInterfaces.lan;
    family = "inet"; address ="10.3.0.1"; prefixLength = 16;
  };

  services.ntp = svc.ntp.build {
    pools = { "pool.ntp.org" = ["iburst"]; };
    makestep = { threshold = 1.0; limit = 3; };
  };

  services.sshd = svc.ssh.build { };

  users.root = {
    passwd = "";
  };

  services.dns =
    let interface = services.int;
    in svc.dnsmasq.build {
      inherit interface;
      ranges = [
        "10.3.0.10,10.3.0.240"
        # ra-stateless: sends router advertisements with the O and A
        # bits set, and provides a stateless DHCP service. The client
        # will use a SLAAC address, and use DHCP for other
        # configuration information.
        "::,constructor:$(output ${interface} ifname),ra-stateless"
      ];

      domain = "example.org";
    };

  defaultProfile.packages = with pkgs; [
    figlet
  ];
}
