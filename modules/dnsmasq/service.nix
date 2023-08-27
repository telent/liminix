{
  liminix
, dnsmasq
, serviceFns
, lib
}:
{
  interface
, user
, domain
, group
, ranges
, upstreams
, resolvconf
}:
let
  name = "${interface.name}.dnsmasq";
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep;
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
    --interface=$(output ${interface} ifname) \
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
