{
  liminix
, odhcp6c
, odhcp-script
}:
{ interface } :
let
  inherit (liminix.services) longrun;
  name = "dhcp6c.${interface.name}";
in longrun {
  inherit name;
  notification-fd = 10;
  run = ''
    export SERVICE_STATE=$SERVICE_OUTPUTS/${name}
    ${odhcp6c}/bin/odhcp6c -s ${odhcp-script} -e -v -p /run/${name}.pid -P0 $(output ${interface} ifname)
    )
  '';
  dependencies = [ interface ];
}
