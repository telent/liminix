{
  liminix
, busybox
} :
let inherit (liminix.services) longrun;
in
interface: { ... } @ args: longrun {
  name = "${interface.device}.udhcp";
  run = "${busybox}/bin/udhcpc -f -i ${interface.device}";
}
