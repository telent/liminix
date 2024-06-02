{
  liminix
, lib
, svc
}:
{ partlabel, mountpoint, options, fstype }:
let
  inherit (liminix.services) longrun oneshot;
  device = "/dev/disk/by-partlabel/${partlabel}";
  options_string =
    if options == [] then "" else "-o ${lib.concatStringsSep "," options}";
  mount_service = oneshot {
    name = "mount.${lib.escapeURL mountpoint}";
    timeout-up = 3600;
    up = "mount -t ${fstype} ${options_string} ${device} ${mountpoint}";
    down = "umount ${mountpoint}";
  };
in svc.uevent-rule.build {
  service = mount_service;
  symlink = device;
  terms = {
    partname = partlabel;
    devtype = "partition";
  };
}
