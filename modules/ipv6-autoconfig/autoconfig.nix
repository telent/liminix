{
  liminix,
  writeAshScript,
  serviceFns,
  lib,
}:
{
  interface,
  role,
  sysctl,
}:
let
  inherit (liminix.services) oneshot;
  inherit (lib) recursiveUpdate;
  name = "${interface.name}.autoconfig";
  sysctls =
    let
      s = recursiveUpdate {
        autoconf = "1";
        accept_ra = (role == "host");
      } sysctl;
    in
    liminix.writeSysctls s;
in
oneshot {
  inherit name;
  dependencies = [ interface ];
  up = ''
    cd /proc/sys/net/ipv6/conf/$(output ${interface} ifname)
    ${sysctls}
  '';
  down = ''
    cd /proc/sys/net/ipv6/conf/$(output ${interface} ifname)
    echo "0" > autoconf
    echo "0" > accept_ra
  '';
}
