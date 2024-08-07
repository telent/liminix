{
  liminix
, lib
, ppp
, pppoe
, writeAshScript
, serviceFns
} :
{ interface,
  ppp-options,
  lcpEcho,
  username,
  password,
  debug
}:
let
  inherit (liminix.services) longrun;
  inherit (lib) optional optionals;
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
  ppp-options' = ["+ipv6" "noauth"]
    ++ optional debug "debug"
    ++ optionals (username != null) ["name" username]
    ++ optionals (password != null) ["password" password]
    ++ optional lcpEcho.adaptive "lcp-echo-adaptive"
    ++ optionals (lcpEcho.interval != null)
      ["lcp-echo-interval" (builtins.toString lcpEcho.interval)]
    ++ optionals (lcpEcho.failure != null)
      ["lcp-echo-failure" (builtins.toString lcpEcho.failure)]
    ++ ppp-options
    ++ ["ip-up-script" ip-up
        "ipv6-up-script" ip6-up
        "ipparam" name
        "nodetach"
        "usepeerdns"
        "logfd" "2"
       ];
  timeoutOpt = if lcpEcho.interval != null then "-T ${builtins.toString (4 * lcpEcho.interval)}" else "";
in
longrun {
  inherit name;
  run = ''
    . ${serviceFns}
    echo Starting pppoe, pppd pid is $$
    exec ${ppp}/bin/pppd pty "${pppoe}/bin/pppoe ${timeoutOpt}  -I $(output ${interface} ifname)" ${lib.concatStringsSep " " ppp-options'}
  '';
  notification-fd = 10;
  timeout-up = if lcpEcho.failure != null
               then (10 + lcpEcho.failure * lcpEcho.interval) * 1000
               else 60 * 1000;
  dependencies = [ interface ];
}
