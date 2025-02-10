{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) liminix;
  inherit (lib) mkOption types;

  inherit (pkgs.liminix.services) oneshot target;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) serviceFns;
  svc = config.system.service;
  cfg = config.profile.wap;

  hostaps =
    let
      defaults = {
        auth_algs = 1; # 1=wpa2, 2=wep, 3=both
        wpa = 2; # 1=wpa, 2=wpa2, 3=both
        wpa_key_mgmt = "WPA-PSK";
        wpa_pairwise = "TKIP CCMP"; # auth for wpa (may not need this?)
        rsn_pairwise = "CCMP"; # auth for wpa2
      };
    in
    lib.mapAttrs' (
      name: value:
      let
        attrs = defaults // { ssid = name; } // value;
      in
      lib.nameValuePair "hostap-${name}" (
        svc.hostapd.build {
          interface = attrs.interface;
          params = lib.filterAttrs (k: v: k != "interface") attrs;
        }
      )
    ) cfg.wireless.networks;

in
{
  imports = [
    ../wlan.nix
    ../network
    ../hostapd
    ../bridge
    { config.services = hostaps; }
  ];

  options.profile.wap = {
    interfaces = mkOption {
      type = types.listOf liminix.lib.types.interface;
      default = [ ];
    };
    wireless = mkOption {
      type = types.attrsOf types.anything;
    };
  };
  config = {

    services.int = svc.bridge.primary.build {
      ifname = "int";
    };

    services.bridge = svc.bridge.members.build {
      primary = config.services.int;
      members = cfg.interfaces;
    };

    services.dhcpc = svc.network.dhcp.client.build {
      interface = config.services.int;
      dependencies = [ config.services.hostname ];
    };

    services.defaultroute4 = svc.network.route.build {
      via = "$(output ${config.services.dhcpc} router)";
      target = "default";
      dependencies = [ config.services.dhcpc ];
    };

    services.resolvconf = oneshot rec {
      dependencies = [ config.services.dhcpc ];
      name = "resolvconf";
      # CHECK: https://udhcp.busybox.net/README.udhcpc says
      # 'A list of DNS server' but doesn't say what separates the
      # list members. Assuming it's a space or other IFS character
      up = ''
        ( in_outputs ${name}
        for i in $(output ${config.services.dhcpc} dns); do
          echo "nameserver $i" > resolv.conf
        done
        )
      '';
    };
    filesystem = dir {
      etc = dir {
        "resolv.conf" = symlink "${config.services.resolvconf}/.outputs/resolv.conf";
      };
    };
  };
}
