{
  liminix
, lib
, busybox
, ppp
, pppoe
, writeAshScript
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
    outputs=/run/service-state/${name}.service/
    mkdir -p $outputs
    (cd $outputs
    echo $1 > ifname
    echo $2 > tty
    echo $3 > speed
    echo $4 > address
    echo $5 > peer-address
    )
    echo >/proc/self/fd/10
  '';
  ppp-options' = ppp-options ++ [
    "ip-up-script" ip-up
    "ipparam" name
    "nodetach"
  ];

in
longrun {
  inherit name;
  run = "${ppp}/bin/pppd pty '${pppoe}/bin/pppoe -I ${interface.device}' ${lib.concatStringsSep " " ppp-options'}" ;
  notification-fd = 10;
  dependencies = [ interface ];
}
