{
  liminix
, lib
}:
{ device, mountpoint, options, fstype }:
let
  inherit (liminix.services) oneshot;
in oneshot {
  name = "mount.${lib.escapeURL mountpoint}";
  up = ''
    while ! findfs ${device}; do
      echo waiting for device ${device}
      sleep 1
    done
    mount -t ${fstype} -o ${lib.concatStringsSep "," options} ${device} ${mountpoint}
  '';
  down = "umount ${mountpoint}";
}
