{
  liminix
, writeAshScript
, serviceFns
, lib
} :
{ interface }:
let
  inherit (liminix.services) longrun;
  name = "${interface.name}.dhcpc";
  script = writeAshScript "dhcp-notify"  { } ''
    . ${serviceFns}
    exec 2>&1
    action=$1

    set_address() {
        ip address replace $ip/$mask dev $interface
        (in_outputs ${name}
         for i in lease mask ip router siaddr dns serverid subnet opt53 interface ; do
            printenv $i > $i
         done)
    }
    case $action in
      deconfig)
        ip address flush $interface
        ip link set up dev $interface
        ;;
      bound)
        # this doesn't actually replace, it adds a new address.
        set_address
        echo  >/proc/self/fd/10
        ;;
      renew)
        set_address
        ;;
      nak)
        echo "received NAK on $interface"
        ;;
    esac
  '';
in longrun {
  inherit name;
  run = "/bin/udhcpc -f -i $(output ${interface} ifname) -x hostname:$(cat /proc/sys/kernel/hostname) -s ${script}";
  notification-fd = 10;
  dependencies = [ interface ];
}
