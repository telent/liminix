## Base options
## ============


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs.liminix.networking) address interface;
  inherit (pkgs.liminix.services) bundle;

  type_service = pkgs.liminix.lib.types.service;

in {
  options = {
    # analogous to nixos systemPackages, but we don't symlink into
    # /run/current-system, we just add the paths in /etc/profile
    defaultProfile = {
      packages = mkOption {
        type = types.listOf types.package;
      };
    };
    services = mkOption {
      type = types.attrsOf type_service;
    };
    filesystem = mkOption { type = types.anything; };
    rootfsType =  mkOption {
      default = "squashfs";
      type = types.str;
    };
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
        # mostly the values are y n or m, but sometimes
        # other strings are also used
        type = types.attrsOf types.nonEmptyStr;
      };
    };
    boot = {
      commandLine = mkOption {
        type = types.listOf types.nonEmptyStr;
        default = [];
      };
      tftp = {
        loadAddress = mkOption { type = types.str; };
        # These names match the uboot environment variables. I reserve
        # the right to change them if I think of better ones.
        ipaddr =  mkOption { type = types.str; };
        serverip =  mkOption { type = types.str; };
      };
    };
  };
  config = {
    defaultProfile.packages = with pkgs;
      [ s6 s6-init-bin execline s6-linux-init s6-rc ];

    hardware.networkInterfaces = {
      lo =
        let iface = interface { type = "loopback"; device = "lo";};
        in bundle {
          name = "loopback";
          contents = [
            (address iface { family = "inet4"; address ="127.0.0.1"; prefixLength = 8;})
            (address iface { family = "inet6"; address ="::1"; prefixLength = 128;})
          ];
        };
    };

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
    boot.commandLine = [
      "console=ttyS0,115200 panic=10 oops=panic init=/bin/init loglevel=8"
      "root=${config.hardware.rootDevice}"
      "rootfstype=${config.rootfsType}"
      "fw_devlink=off"
    ];
    users.root = {
      uid = 0; gid= 0; gecos = "Root of all evaluation";
      dir = "/home/root/";
      passwd = lib.mkDefault "";
      shell = "/bin/sh";
    };
    groups = {
      root = {
        gid = 0; usernames = ["root"];
      };
      system = {
        gid = 1; usernames = ["root"];
      };
    };

    filesystem = dir {
      dev =
        let node = type: major: minor: mode : { inherit type major minor mode; };
        in dir {
          null =    node "c" "1" "3" "0666";
          zero =    node "c" "1" "5" "0666";
          tty =     node "c" "5" "0" "0666";
          console = node "c" "5" "1" "0600";
          pts =     dir {};
        };
      etc = let
        profile = symlink
          (pkgs.writeScript ".profile" ''
           PATH=${lib.makeBinPath config.defaultProfile.packages}:/bin
            export PATH
            '');
      in dir {
        inherit profile;
        ashrc = profile;
      };

      proc = dir {};
      run = dir {};
      sys = dir {};
    };
  };
}
