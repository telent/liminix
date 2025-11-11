{
  liminix,
  odhcp6c,
  odhcp-script,
  svc,
}:
{ interface }:
let
  inherit (liminix.services) longrun;
  inherit (liminix) outputRef;
  name = "dhcp6c.${interface.name}";
  autoconf = svc.ipv6.autoconfig.build {
    inherit interface;
  };
  service = longrun {
    inherit name;
    notification-fd = 10;
    run = ''
      export SERVICE_STATE=$SERVICE_OUTPUTS/${name}
      ifname=$(output ${interface} ifname)
      test -n "$ifname" && ${odhcp6c}/bin/odhcp6c -s ${odhcp-script} -e -v -p /run/${name}.pid -P0 $ifname
      )
    '';
    dependencies = [
      interface
      autoconf
    ];
  };
in
svc.secrets.subscriber.build {
  # if the ppp service gets restarted, the interface may be different and
  # we will have to restart dhcp on the new one
  watch = [ (outputRef interface "ifindex") ];
  action = "restart";
  inherit service;
}
