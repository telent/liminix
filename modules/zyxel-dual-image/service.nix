{
  liminix,
  lib,
  zyxel-bootconfig,
}:
{
  ensureActiveImage,
  primaryMtdPartition,
  secondaryMtdPartition,
  bootConfigurationMtdPartition,
  kernelCommandLineSource,
}:
let
  inherit (liminix.services) oneshot;
  activeImageIndex = if ensureActiveImage == "primary" then 0 else 1;
in
oneshot {
  name = "zyxel-boot-configure";
  up = ''
    set -- $(cat /proc/device-tree/chosen/bootargs)
    for x in "$@"; do
        case "$x" in
            bootImage=*)
            BOOT_IMAGE="''${x#bootImage=}"
            echo "Current boot image is $BOOT_IMAGE."
            ;;
        esac
    done

    if test -z "$BOOT_IMAGE"; then
      echo "No valid image was provided in the kernel command line."
      exit 1
    else
      ${lib.getExe zyxel-bootconfig} ${bootConfigurationMtdPartition} set-image-status "$BOOT_IMAGE" valid
      ${lib.getExe zyxel-bootconfig} ${bootConfigurationMtdPartition} set-active-image ${toString activeImageIndex}

      echo "Active image is now ${ensureActiveImage}"
    fi
  '';
}
