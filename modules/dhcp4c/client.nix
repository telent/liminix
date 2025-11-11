{
  liminix,
  writeAshScript,
  serviceFns,
  writeFennel,
  anoia,
  linotify,
  lualinux,
  s6-rc-up-tree,
  lib,
}:
{ interface }:
let
  inherit (liminix.services) longrun;
  name = "${interface.name}.dhcpc";
  script = writeAshScript "dhcp-notify" { } ''
    . ${serviceFns}
    exec 2>&1
    action=$1
    unset_address() {
      ip -4 address flush $interface
      ip link set up dev $interface
    }
    set_address() {
        ip address replace $ip/$mask dev $interface
        (in_outputs ${name}
         for i in lease mask ip router siaddr dns serverid subnet opt53 interface ; do
            (printenv $i || true) > $i
         done
         touch state)
    }
    case $action in
      deconfig)
        unset_address
        ;;
      bound)
        # this doesn't actually replace, it adds a new address.
        set_address
        ;;
      renew)
        # renewal mut be for an address we already have, so do nothing
        ;;
      nak)
        echo "received NAK on $interface"
        unset_address
        ;;
    esac
  '';
  service = longrun {
    inherit name;
    run = "exec /bin/udhcpc -n -A 15 -f -i $(output ${interface} ifname) -x hostname:$(cat /proc/sys/kernel/hostname) -s ${script}";
    dependencies = [ interface ];
  };
  controlled-name = "${name}-lease-acquired";
  watcher = longrun {
    name = "${name}-watcher";
    dependencies = [ service ];
    run =
      let
        script = writeFennel "dhcp-lease-watcher" {
          packages = [
            anoia
            linotify
            lualinux
          ];
          mainFunction = "run";
        } ./lease-watcher.fnl;
      in
      ''
        export PATH=${s6-rc-up-tree}/bin/:$PATH
        ${script} ${service} ${controlled-name}
      '';
  };
in
longrun {
  name = controlled-name;
  run = ''
    set -e
    echo dhcp lease acquired $(output ${service} ip)
    (in_outputs ${controlled-name}
     cp $(output_path ${service})/* .
     )
    while sleep 86400 ; do true ; done
  '';
  controller = watcher;
}
