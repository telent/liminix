## Mount
##
## Mount filesystems


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
  mkBoolOption = description : mkOption {
    type = types.bool;
    inherit description;
    default = true;
  };

in {
  options = {
    system.service.mount = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config.system.service = {
    mount = liminix.callService ./service.nix {
      device = mkOption {
        type = types.str;
        example = "/dev/sda1";
      };
      mountpoint = mkOption {
        type = types.str;
        example = "/mnt/media";
      };
      options = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["noatime" "ro" "sync"];
      };
      fstype = mkOption {
        type = types.str;
        default = "auto";
        example = "vfat";
      };
    };
  };
  config.programs.busybox  = {
    applets = ["blkid" "findfs"];
    options = {
      FEATURE_BLKID_TYPE = "y";
      FEATURE_MOUNT_FLAGS = "y";
      FEATURE_MOUNT_LABEL = "y";
      FEATURE_VOLUMEID_EXT = "y";
    };
  };
}
