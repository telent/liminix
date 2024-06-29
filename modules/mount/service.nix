{
  liminix
, lib
, svc
}:
{ partlabel, mountpoint, options, fstype }:
let
  inherit (liminix.services) oneshot;
  device = "/dev/disk/by-partlabel/${partlabel}";
  name = "mount.${lib.strings.sanitizeDerivationName (lib.escapeURL mountpoint)}";
  options_string =
    if options == [] then "" else "-o ${lib.concatStringsSep "," options}";
  controller = svc.uevent-rule.build {
    serviceName = name;
    symlink = device;
    terms = {
      partname = partlabel;
      devtype = "partition";
    };
  };
in oneshot {
  inherit name;
  timeout-up = 3600;
  up = "mount -t ${fstype} ${options_string} ${device} ${mountpoint}";
  down = "umount ${mountpoint}";
  inherit controller;
}
