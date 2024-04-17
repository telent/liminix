{
  liminix
, uevent-watch
, lib
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
in longrun {
  name = "watch-mount.${lib.strings.sanitizeDerivationName mountpoint}";
  isTrigger = true;
  buildInputs = [ mount_service ];

  run = ''
    ${uevent-watch}/bin/uevent-watch -s ${mount_service.name} -n ${device} partname=${partlabel} devtype=partition
  '';
}
