{ config, pkgs, lib, ... } :
let
  svc = config.system.service;
  inherit (pkgs.liminix.services) longrun oneshot ;

in rec {
  imports = [
    ../modules/network
    ../modules/dnsmasq
    ../modules/ssh
    ../modules/tls-certificate
  ];

  hostname = "hello";

  # configure the internal network (LAN) with an address
  services.int = svc.network.address.build {
    interface = config.hardware.networkInterfaces.lan;
    family = "inet"; address ="10.3.0.1"; prefixLength = 16;
  };

  filesystem =
    let inherit (pkgs.pseudofile) file dir symlink;
    in dir {
      etc = dir {
        hosts =  {
          type = "f";
          file = "127.0.0.1 localhost\n10.0.2.2 loaclhost.telent.net\n";
          mode = "0444";
        };
      };
    };

  services.sshd = svc.ssh.build { };

  services.lan-address-for-secrets =
    svc.network.address.build {
      interface = config.hardware.networkInterfaces.lan;
      family = "inet"; address ="10.0.2.15"; prefixLength = 24;
    };

  # services.client-cert = svc.tls-certificate.certifix-client.build {
  #   caCertificate = builtins.readFile /var/lib/certifix/certs/ca.crt;
  #   subject = "C=GB,ST=London,O=Telent,OU=devices,CN=${config.hostname}";
  #   secret = builtins.readFile ../challengePassword;
  #   serviceUrl = "https://loaclhost.telent.net:19613/sign";
  # };

  # logging.shipping = {
  #   enable = true;
  #   service = longrun {
  #     name = "ship-logs";
  #     dependencies = [ config.services.client-cert ];
  #     run =
  #       let path = lib.makeBinPath (with pkgs; [ s6-networking s6 ]);
  #       in ''
  #         PATH=${path}:$PATH \
  #         CAFILE=${/var/lib/certifix/certs/ca.crt} \
  #         KEYFILE=$(output_path ${services.client-cert} key) \
  #         CERTFILE=$(output_path ${services.client-cert} cert) \
  #         s6-tlsclient -k loaclhost.telent.net -h -y loaclhost.telent.net 19612 \
  #         fdmove -c 1 7 cat
  #       '';
  #   };
  # };

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
    figlet openssl
  ];
}
