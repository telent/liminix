## Kernel-related options
## ======================
##
##

{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix openwrt;

  mergeConditionals =
    conf: conditions:
    # for each key in conditions, if it is present in conf
    # then merge the associated value into conf
    lib.foldlAttrs (
      acc: name: value:
      if (conf ? ${name}) && (conf.${name} != "n") then acc // value else acc
    ) conf conditions;
in
{
  options = {
    kernel = {
      src = mkOption {
        type = types.path;
        default = openwrt.kernelSrc;
      };
      version = mkOption {
        type = types.str;
        default = openwrt.kernelVersion;
      };
      modular = mkOption {
        type = types.bool;
        default = true;
        description = "support loadable kernel modules";
      };
      extraPatchPhase = mkOption {
        default = "true";
        type = types.lines;
      };
      config = mkOption {
        description = ''
          Kernel config options, as listed in Kconfig* files in the
          kernel source tree. Do not include the leading "CONFIG_"
          prefix when defining these.  Most values are "y", "n" or "m",
          but sometimes other strings are also used.
        '';
        type = types.attrsOf types.nonEmptyStr;
        example = lib.literalExpression ''
          {
            BRIDGE = "y";
            TMPFS = "y";
            FW_LOADER_USER_HELPER = "n";
          };
        '';
      };
      conditionalConfig = mkOption {
        description = ''
          Kernel config options that should only be applied when
          some other option is present.
        '';
        type = types.attrsOf (types.attrsOf types.nonEmptyStr);
        default = { };
        example = {
          USB = {
            USB_XHCI_MVEBU = "y";
            USB_XHCI_HCD = "y";
          };
        };
      };
      makeTargets = mkOption {
        type = types.listOf types.str;
      };
    };
  };
  config = {
    system.outputs.kernel =
      let
        mergedConfig = mergeConditionals config.kernel.config config.kernel.conditionalConfig;
      in
      liminix.builders.kernel.override {
        config = mergedConfig;
        inherit (config.kernel) version src extraPatchPhase;
        targets = config.kernel.makeTargets;
      };

    kernel = rec {
      modular = true; # disabling this is not yet supported
      makeTargets = [ "vmlinux" ];
      config = {
        IKCONFIG = "y";
        IKCONFIG_PROC = "y";
        PROC_FS = "y";

        MODULES = if modular then "y" else "n";
        MODULE_UNLOAD = if modular then "y" else "n";
        DEBUG_FS = "y";

        # basic networking protocols
        NET = "y";
        UNIX = "y";
        INET = "y";
        IPV6 = "y";
        PACKET = "y"; # for ppp, tcpdump ...
        SYSVIPC = "y";

        NETDEVICES = "y"; # even PPP needs this

        # disabling this option causes the kernel to use an "empty"
        # initramfs instead: it has a /dev/console node and not much
        # else.  Note that pid 1 is started *before* the root
        # filesystem is mounted and it expects /dev/console to be
        # present already
        BLK_DEV_INITRD = lib.mkDefault "n"; # overriden by initramfs module

        # s6-linux-init mounts this on /dev
        DEVTMPFS = "y";
        # some or all of these may be fix for "tmpfs: Unknown parameter 'mode'" error
        TMPFS = "y";
        TMPFS_POSIX_ACL = "y";
        TMPFS_XATTR = "y";

        FW_LOADER = "y";
        FW_LOADER_COMPRESS = "y";
        # We don't have a user helper, so we get multiple 60s pauses
        # at boot time unless we disable trying to call it.
        # https://lkml.org/lkml/2013/8/5/175
        FW_LOADER_USER_HELPER = "n";
      };
    };
  };
}
