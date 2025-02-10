## Boot blessing via Zyxel
## =======================
## Boot blessing is the process to bless a particular boot configuration
## It is commonly encountered in devices with redundant partitions
## for automatic recovery of broken upgrades.
## This is also known as A/B schemas, where A represents the primary partition
## and B the secondary partition used for recovery.
## To use boot blessing on Liminix, you need to have the support of
## your bootloader to help you boot on the secondary partition in case of
## failure on the primary partition. The exact details are specifics to your device.
## See the Zyxel NWA50AX for an example.
## TODO: generalize this module.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in
{
  options.boot.zyxel-dual-image = mkOption {
    type = liminix.lib.types.serviceDefn;
  };

  config.boot.zyxel-dual-image = config.system.callService ./service.nix {
    ensureActiveImage = mkOption {
      type = types.enum [
        "primary"
        "secondary"
      ];
      default = "primary";
      description = ''
        At boot, ensure that the active image is the one specified.

                If you are already on a broken image, you need to manually boot
                into the right image via `atgo <image index>` in U-Boot.
      '';
    };

    kernelCommandLineSource = mkOption {
      type = types.enum [
        "/proc/cmdline"
        "/proc/device-tree/chosen/bootargs"
      ];
      default = "/proc/device-tree/chosen/bootargs";
      description = ''
        Kernel command line arguments source file.
                On MIPS, Liminix embeds the kernel command line in /proc/device-tree/chosen/bootargs-override.

                In this instance, it does not get concatenated with `/proc/cmdline`.
                Therefore you may prefer to source it from another place, like `/proc/device-tree/chosen/bootargs`.
      '';
    };

    primaryMtdPartition = mkOption {
      type = types.str;
      description = "Primary MTD partition device node, i.e. for image 0.";
    };

    secondaryMtdPartition = mkOption {
      type = types.str;
      description = "Secondary MTD partition device node, i.e. for image 1.";
    };

    bootConfigurationMtdPartition = mkOption {
      type = types.str;
      description = "Boot configuration MTD partition device node.";
    };
  };
}
