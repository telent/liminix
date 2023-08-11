## Kernel-related options
## ======================


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs.liminix.networking) address interface;
  inherit (pkgs.liminix.services) bundle;

  type_service = pkgs.liminix.lib.types.service;

in {
  options = {
    kernel = {
      src = mkOption { type = types.package; } ;
      modular = mkOption {
        type = types.bool;
        default = true;
        description = "support loadable kernel modules";
      };
      extraPatchPhase = mkOption {
        default = "true";
        type = types.lines;
      } ;
      config = mkOption {
        description = ''
          Kernel config options, as listed in Kconfig* files in the
          kernel source tree. Do not include the leading "CONFIG_"
          prefix when defining these.  Most values are "y", "n" or "m",
          but sometimes other strings are also used.
        '';
        type = types.attrsOf types.nonEmptyStr;
      };
    };
  };
  config = {
    kernel = rec {
      modular = true; # disabling this is not yet supported
      config = {
        IKCONFIG = "y";
        IKCONFIG_PROC = "y";
        PROC_FS = "y";

        KEXEC = "y";
        MODULES = if modular then "y" else "n";
        MODULE_SIG = if modular then "y" else "n";
        DEBUG_FS = "y";

        MIPS_BOOTLOADER_CMDLINE_REQUIRE_COOKIE = "y";
        MIPS_BOOTLOADER_CMDLINE_COOKIE = "\"liminix\"";
        MIPS_CMDLINE_DTB_EXTEND = "y";

        # basic networking protocols
        NET = "y";
        UNIX = "y";
        INET = "y";
        IPV6 = "y";
        PACKET = "y";           # for ppp, tcpdump ...
        SYSVIPC= "y";

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
