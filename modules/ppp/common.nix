{ writeAshScript, liminix, svc, lib, serviceFns, output-template }:
{
  command,
  name,
  debug
, username,
  password,
  lcpEcho,
  ppp-options,
  dependencies ? []
} :
let
  inherit (lib) optional optionals escapeShellArgs concatStringsSep;
  inherit (liminix.services) longrun;
  inherit (builtins) toJSON toString typeOf;

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
          string = toJSON;
          int = toJSON;
          lambda = (o: "output(${toJSON (o "service")}, ${toJSON (o "path")})");
        }.${typeOf o}) o;
    in  o: "{{ ${v o} }}";

  ppp-options' =
    ["+ipv6" "noauth"]
    ++ optional debug "debug"
    ++ optionals (username != null) ["name" (literal_or_output username)]
    ++ optionals (password != null) ["password" (literal_or_output password)]
    ++ optional lcpEcho.adaptive "lcp-echo-adaptive"
    ++ optionals (lcpEcho.interval != null)
      ["lcp-echo-interval" (toString lcpEcho.interval)]
    ++ optionals (lcpEcho.failure != null)
      ["lcp-echo-failure" (toString lcpEcho.failure)]
    ++ ppp-options
    ++ ["ip-up-script" ip-up
        "ipv6-up-script" ip6-up
        "ipparam" name
        "nodetach"
        "nodefaultroute"
        "logfd" "2"
       ];
  service = longrun {
    inherit name;
    run = ''
      mkdir -p /run/${name}
      chmod 0700 /run/${name}
      in_outputs ${name}
      echo ${escapeShellArgs ppp-options'} | ${output-template}/bin/output-template '{{' '}}' > /run/${name}/ppp-options
      ${command}
    '';
    notification-fd = 10;
    timeout-up = if lcpEcho.failure != null
                 then (10 + lcpEcho.failure * lcpEcho.interval) * 1000
                 else 60 * 1000;
    inherit dependencies;
  };
in svc.secrets.subscriber.build {
  watch = lib.filter (n: typeOf n=="lambda") [ username password ];
  inherit service;
}
