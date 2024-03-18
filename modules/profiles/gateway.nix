{ config, pkgs, lib, ... } :
let
  svc = config.system.service;
  cfg = config.profile.gateway;
  inherit (lib) mkOption mkEnableOption mkIf mdDoc types optional optionals;
  inherit (pkgs) liminix;
  inherit (liminix.services) bundle oneshot;
  hostaps =
    let
      defaults = {
        auth_algs = 1; # 1=wpa2, 2=wep, 3=both
        wpa = 2; # 1=wpa, 2=wpa2, 3=both
        wpa_key_mgmt = "WPA-PSK";
        wpa_pairwise = "TKIP CCMP"; # auth for wpa (may not need this?)
        rsn_pairwise = "CCMP"; # auth for wpa2
      };
    in lib.mapAttrs'
      (name : value :
        let
          attrs = defaults // { ssid = name; } // value;
        in lib.nameValuePair
          "hostap-${name}"
          (svc.hostapd.build {
            interface = attrs.interface;
            params = lib.filterAttrs (k: v: k != "interface") attrs;
          }))
      cfg.wireless.networks;
in {

  options.profile.gateway = {
    lan = {
      interfaces = mkOption {
        type = types.listOf liminix.lib.types.interface;
        default = [];
      };
      address = mkOption {
        type = types.attrs;
      };
    };
    wan = {
      interface = mkOption { type = liminix.lib.types.interface; };
      username =  mkOption { type = types.str; };
      password =  mkOption { type = types.str; };
      dhcp6.enable = mkOption { type = types.bool; };
    };

    wireless = mkOption {
      type = types.attrsOf types.anything;
    };
  };

  imports = [
    ../wlan.nix
    ../network
    ../ppp
    ../dnsmasq
    ../dhcp6c
    ../firewall
    ../hostapd
    ../bridge
    ../ntp
    ../ssh
    { config.services = hostaps; }
  ];

  config = {
    services.int = svc.network.address.build ({
      interface = svc.bridge.primary.build { ifname = "int"; };
    } // cfg.lan.address);

    services.bridge =  svc.bridge.members.build {
      primary = config.services.int;
      members = cfg.lan.interfaces;
    };

    services.wan = svc.pppoe.build {
      inherit (cfg.wan) interface;
      ppp-options = [
        "debug" "+ipv6" "noauth"
        "name" cfg.wan.username
        "password" cfg.wan.password
      ];
    };

    services.packet_forwarding = svc.network.forward.build { };

    services.dhcp6c =
      let
        client = svc.dhcp6c.client.build {
          interface = config.services.wan;
        };
        bundl = bundle {
          name = "dhcp6c";
          contents = [
            (svc.dhcp6c.prefix.build {
              inherit client;
              interface = config.services.int;
            })
            (svc.dhcp6c.address.build {
              inherit client;
              interface = config.services.wan;
            })
          ];
        };
      in mkIf cfg.wan.dhcp6.enable bundl;
  };

#   services.dns =
#     let interface = services.int;
#     in svc.dnsmasq.build {
#       resolvconf = services.resolvconf;
#       inherit interface;
#       ranges = [
#         "${secrets.lan.prefix}.10,${secrets.lan.prefix}.240"
#         # ra-stateless: sends router advertisements with the O and A
#         # bits set, and provides a stateless DHCP service. The client
#         # will use a SLAAC address, and use DHCP for other
#         # configuration information.
#         "::,constructor:$(output ${interface} ifname),ra-stateless"
#       ];

#       # You can add static addresses for the DHCP server here.  I'm
#       # not putting my actual MAC addresses in a public git repo ...
#       hosts = { } // lib.optionalAttrs (builtins.pathExists ./static-leases.nix) (import ./static-leases.nix);
#       upstreams = [ "/${secrets.domainName}/" ];
#       domain = secrets.domainName;
#     };


#   services.resolvconf = oneshot rec {
#     dependencies = [ services.wan ];
#     name = "resolvconf";
#     up = ''
#       . ${serviceFns}
#       ( in_outputs ${name}
#        echo "nameserver $(output ${services.wan} ns1)" > resolv.conf
#        echo "nameserver $(output ${services.wan} ns2)" >> resolv.conf
#        chmod 0444 resolv.conf
#       )
#     '';
#   };

#   filesystem =
#     let inherit (pkgs.pseudofile) dir symlink;
#     in dir {
#       etc = dir {
#         "resolv.conf" = symlink "${services.resolvconf}/.outputs/resolv.conf";
#       };
#     };

#   services.defaultroute4 = svc.network.route.build {
#     via = "$(output ${services.wan} address)";
#     target = "default";
#     dependencies = [ services.wan ];
#   };

#   services.defaultroute6 = svc.network.route.build {
#     via = "$(output ${services.wan} ipv6-peer-address)";
#     target = "default";
#     interface = services.wan;
#   };

#   services.firewall = svc.firewall.build {
#     ruleset =
#       let defaults = import ./demo-firewall.nix;
#       in lib.recursiveUpdate defaults secrets.firewallRules;
#   };



 }
