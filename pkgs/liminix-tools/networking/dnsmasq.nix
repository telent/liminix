{
  liminix
, dnsmasq
, lib
}:
{
  user ? "dnsmasq"
, group ? "dnsmasq"
, interface
, upstreams ? []
, ranges
, domain
} :
let
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep;
  name = "${interface.device}.dnsmasq";
in longrun {
  inherit name;
  dependencies = [ interface ];
  run = ''
    ${dnsmasq}/bin/dnsmasq \
    --user=${user} \
    --domain=${domain} \
    --group=${group} \
    --interface=${interface.device} \
    ${lib.concatStringsSep " " (builtins.map (r: "--dhcp-range=${r}") ranges)} \
    ${lib.concatStringsSep " " (builtins.map (r: "--server=${r}") upstreams)} \
    --keep-in-foreground \
    --dhcp-authoritative \
    --no-resolv \
    --log-dhcp \
    --enable-ra \
    --log-debug \
    --log-facility=- \
    --dhcp-leasefile=/run/${name}.leases \
    --pid-file=/run/${name}.pid
  '';
}
