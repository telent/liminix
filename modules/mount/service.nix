{
  liminix
, lib
}:
{ device, mountpoint, options, fstype }:
let
  inherit (liminix.services) longrun oneshot;
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

  # This accommodates bringing the service up when the device appears.
  # It doesn't bring it down on unplug because unmount will probably
  # fail anyway (so don't do that)
  run = ''
    while ! findfs ${device}; do
      echo waiting for device ${device}
      sleep 1
    done
    s6-rc -b -u change ${mount_service.name}
  '';
}
