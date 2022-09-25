{
  liminix
, lib
, busybox
, ppp
, pppoe
, writeShellScript
} :
let
  inherit (liminix.services) longrun;
  ip-up = writeShellScript "ip-up" ''
action=$1
env > /run/udhcp.values

set_address() {
    ip address replace $ip/$mask dev $interface
    mkdir -p data/outputs
    for i in lease mask ip router siaddr dns serverid subnet opt53 interface ; do
        echo ''${!i} > data/outputs/$i
    done
}
case $action in
  deconfig)
    ip address flush $interface
    ip link set up dev $interface
    ;;
  bound)
    # this doesn't actually replace, it adds a new address.
    set_address
    ;;
  renew)
    set_address
    ;;
  nak)
    echo "received NAK on $interface"
    ;;
esac
'';

in
interface: {
  synchronous ? false
, ppp-options ? []
, ...
} @ args: longrun {
  name = "${interface.device}.ppppoe";
  run = "${ppp}/bin/pppd pty '${pppoe}/bin/pppoe -I ${interface.device}' ${lib.concatStringsSep " " ppp-options}" ;
}
