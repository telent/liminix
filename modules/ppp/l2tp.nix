{
  liminix
, lib
, svc
, output-template
, writeAshScript
, writeText
, serviceFns
, xl2tpd
} :
{ lns,
  ppp-options,
  lcpEcho,
  username,
  password,
  debug
}:
let
  inherit (liminix.services) longrun;
  inherit (lib) optional optionals escapeShellArgs concatStringsSep;
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

  literal_or_output =
    let v = o: ({
          string = builtins.toJSON;
          int = builtins.toJSON;
          lambda = (o: "output(${builtins.toJSON (o "service")}, ${builtins.toJSON (o "path")})");
        }.${builtins.typeOf o}) o;
    in  o: "{{ ${v o} }}";

  ppp-options' =
    ["+ipv6" "noauth"]
    ++ optional debug "debug"
    ++ optionals (username != null) ["name" (literal_or_output username)]
    ++ optionals (password != null) ["password" (literal_or_output password)]
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

  conf = writeText "xl2tpd.conf" ''
    [lac upstream]
    lns = ${lns}
    require authentication = no
    pppoptfile = /run/${name}/ppp-options
    autodial = yes
    redial = yes
    redial timeout = 1
    max redials = 2 # this gives 1 actual retry, as xl2tpd can't count
  '';
  control = "/run/${name}/control";
  service = longrun {
    inherit name;
    run = ''
      mkdir -p /run/${name}
      chmod 0700 /run/${name}
      touch ${control}
      in_outputs ${name}
      echo ${escapeShellArgs ppp-options'} | ${output-template}/bin/output-template '{{' '}}' > /run/${name}/ppp-options
      exec ${xl2tpd}/bin/xl2tpd -D -p /run/${name}/${name}.pid -c ${conf} -C ${control} 
    '';
    notification-fd = 10;
  };
in svc.secrets.subscriber.build {
  watch = [ username password ];
  inherit service;
}
