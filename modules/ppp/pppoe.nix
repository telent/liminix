{
  liminix
, lib
, ppp
, pppoe
, writeAshScript
, serviceFns
} :
{ interface, ppp-options }:
let
  inherit (liminix.services) longrun;
  lcp-echo-interval = 4;
  lcp-echo-failure = 3;
  name = "${interface.name}.pppoe";
  ip-up = writeAshScript "ip-up" {} ''
    . ${serviceFns} 
    (in_outputs ${name}
     echo $1 > ifname
     echo $2 > tty
     echo $3 > speed
     echo $4 > address
     echo $5 > peer-address
     echo $DNS1 > ns1
     echo $DNS2 > ns2
    )
    echo >/proc/self/fd/10
  '';
  ip6-up = writeAshScript "ip6-up" {} ''
    . ${serviceFns} 
    (in_outputs ${name}
     echo $4 > ipv6-address
     echo $5 > ipv6-peer-address
    )
    echo >/proc/self/fd/10
  '';
  ppp-options' = ppp-options ++ [
    "ip-up-script" ip-up
    "ipv6-up-script" ip6-up
    "ipparam" name
    "nodetach"
    "usepeerdns"
    "lcp-echo-interval" (builtins.toString lcp-echo-interval)
    "lcp-echo-failure" (builtins.toString lcp-echo-failure)
    "logfd" "2"
  ];
in
longrun {
  inherit name;
  run = ''
    . ${serviceFns}
    echo Starting pppoe, pppd pid is $$
    exec ${ppp}/bin/pppd pty "${pppoe}/bin/pppoe -T ${builtins.toString (4 * lcp-echo-interval)}  -I $(output ${interface} ifname)" ${lib.concatStringsSep " " ppp-options'}
  '';
  notification-fd = 10;
  timeout-up = (10 + lcp-echo-failure * lcp-echo-interval) * 1000;
  dependencies = [ interface ];
}
