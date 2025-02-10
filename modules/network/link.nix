{
  liminix,
  lib,
}:
{
  ifname,
  devpath ? null,
  mtu,
}:
# if devpath is supplied, we rename the interface at that
# path to have the specified name.
let
  inherit (liminix.services) oneshot;
  name = "${ifname}.link";
  rename =
    if devpath != null then
      ''
        oldname=$(cd /sys${devpath} && cd net/ && echo *)
        ip link set ''${oldname} name ${ifname}
      ''
    else
      "";
in
oneshot {
  inherit name;
  up = ''
    ${rename}
    ${liminix.networking.ifup name ifname}
  '';
  down = "ip link set down dev ${ifname}";
}
