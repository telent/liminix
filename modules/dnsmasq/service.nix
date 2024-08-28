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
, hosts
, upstreams
, resolvconf
}:
let
  name = "${interface.name}.dnsmasq";
  inherit (liminix.services) longrun;
  inherit (lib) concatStrings concatStringsSep mapAttrsToList;
  hostOpt = name : { mac, v4, v6, leasetime }:
    let v6s = concatStrings (map (a : ",[${a}]") v6);
    in "--dhcp-host=${mac},${v4}${v6s},${name},${builtins.toString leasetime}";
in
longrun {
  inherit name;
  dependencies = [ interface ];
  run = ''
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
    ${lib.concatStringsSep " " (mapAttrsToList hostOpt hosts)} \
    --no-hosts \
    --log-dhcp \
    --enable-ra \
    --log-facility=- \
    --dhcp-leasefile=$(mkstate ${name})/leases \
    --pid-file=/run/${name}.pid
  '';
    # --log-debug \
    # --log-queries \

}
