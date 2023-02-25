{
  liminix
, lib
, busybox
, ppp
, pppoe
, writeAshScript
, serviceFns
} :
let
  inherit (liminix.services) longrun;
in
interface: {
  synchronous ? false
, ppp-options ? []
, ...
} @ args:
let
  name = "${interface.device}.pppoe";
  ip-up = writeAshScript "ip-up" {} ''
    . ${serviceFns} 
    (cd $(mkoutputs ${name}); umask 0027
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
  ppp-options' = ppp-options ++ [
    "ip-up-script" ip-up
    "ipparam" name
    "nodetach"
    "usepeerdns"
    "logfd" "2"
  ];

in
longrun {
  inherit name;
  run = "${ppp}/bin/pppd pty '${pppoe}/bin/pppoe -I ${interface.device}' ${lib.concatStringsSep " " ppp-options'}" ;
  notification-fd = 10;
  dependencies = [ interface ];
}
