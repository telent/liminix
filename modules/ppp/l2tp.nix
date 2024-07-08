{
  liminix
, writeAshScript
, writeText
, serviceFns
, xl2tpd
} :
{ lns, ppp-options }:
let
  inherit (liminix.services) longrun;
  lcp-echo-interval = 4;
  lcp-echo-failure = 3;
  name = "${lns}.l2tp";
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
  conf = writeText "xl2tpd.conf" ''
    [lac upstream]
    lns = ${lns}
    require authentication = no
    pppoptfile = ${writeText "ppp-options" ppp-options'}
    autodial = yes
    redial = yes
    redial timeout = 1
    max redials = 2 # this gives 1 actual retry, as xl2tpd can't count
  '';
  control = "/run/xl2tpd/control-${name}";
in
longrun {
  inherit name;
  run = ''
    mkdir -p /run/xl2tpd
    touch ${control}
    exec ${xl2tpd}/bin/xl2tpd -D -p /run/xl2tpd/${name}.pid -c ${conf} -C ${control} 
  '';
  notification-fd = 10;
}
