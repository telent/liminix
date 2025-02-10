{ ifwait, liminix }:
{
  state,
  interface,
  service,
}:
let
  inherit (liminix.services) longrun;
in
longrun {
  name = "ifwait.${interface.name}";
  buildInputs = [ service ];
  restart-on-upgrade = true;
  run = ''
    ${ifwait}/bin/ifwait -s ${service.name}  $(output ${interface} ifname) ${state}
  '';
}
