{
  liminix
, dnsmasq
, serviceFns
, lib
}:
let
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep;
  inherit (liminix.lib) typeChecked;
  inherit (lib) mkOption types;

  t = {
    user = mkOption {
      type = types.str;
      default = "dnsmasq";
    };
    group = mkOption {
      type = types.str;
      default = "dnsmasq";
    };
    resolvconf = mkOption {
      type = types.nullOr liminix.lib.types.service;
      default = null;
    };
    interface = mkOption {
      type = liminix.lib.types.service;
      default = null;
    };
    upstreams = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    ranges = mkOption {
      type = types.listOf types.str;
    };
    domain = mkOption {
      type = types.str;
    };
  };
in
params:
let
  inherit (typeChecked "dnsmasq" t params)
    interface user domain group ranges upstreams resolvconf;
  name = "${interface.device}.dnsmasq";
in
longrun {
  inherit name;
  dependencies = [ interface ];
  run = ''
    . ${serviceFns}
    ${dnsmasq}/bin/dnsmasq \
    --user=${user} \
    --domain=${domain} \
    --group=${group} \
    --interface=${interface.device} \
    ${lib.concatStringsSep " " (builtins.map (r: "--dhcp-range=${r}") ranges)} \
    ${lib.concatStringsSep " " (builtins.map (r: "--server=${r}") upstreams)} \
    --keep-in-foreground \
    --dhcp-authoritative \
    ${if resolvconf != null then "--resolv-file=$(output_path ${resolvconf} resolv.conf)" else "--no-resolv"} \
    --no-hosts \
    --log-dhcp \
    --enable-ra \
    --log-debug \
    --log-queries \
    --log-facility=- \
    --dhcp-leasefile=/run/${name}.leases \
    --pid-file=/run/${name}.pid
  '';
}
