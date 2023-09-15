{ config, pkgs, lib, ... } :
let
  inherit (pkgs) serviceFns;
  svc = config.system.service;

in rec {
  imports = [
    ../modules/network
    ../modules/dnsmasq
    ../modules/ssh
  ];

  hostname = "hello";

  # configure the internal network (LAN) with an address
  services.int = svc.network.address.build {
    interface = config.hardware.networkInterfaces.lan;
    family = "inet"; address ="10.3.0.1"; prefixLength = 16;
  };

  services.sshd = svc.ssh.build { };

  users.root = {
    # the password is "secret". Use mkpasswd -m sha512crypt to
    # create this hashed password string
    passwd = "$6$y7WZ5hM6l5nriLmo$5AJlmzQZ6WA.7uBC7S8L4o19ESR28Dg25v64/vDvvCN01Ms9QoHeGByj8lGlJ4/b.dbwR9Hq2KXurSnLigt1W1";
  };

  services.dns =
    let interface = services.int;
    in svc.dnsmasq.build {
      inherit interface;
      ranges = [
        "10.3.0.10,10.3.0.240"
        "::,constructor:$(output ${interface} ifname),ra-stateless"
      ];

      domain = "example.org";
    };

  defaultProfile.packages = with pkgs; [
    figlet
  ];
}
