{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) busybox;
  inherit (pkgs.liminix.networking) address interface;
  inherit (pkgs.liminix.services) bundle;

  type_service = types.package // {
    name = "service";
    description = "s6-rc service";
    check = x: isDerivation x && hasAttr "serviceType" x;
  };

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
    kernel = {
      src = mkOption { type = types.package; } ;
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
    };
  };
  config = {
    defaultProfile.packages = with pkgs;
      [ s6 s6-init-bin busybox execline s6-linux-init s6-rc ];

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
      config = {
        IKCONFIG = "y";
        IKCONFIG_PROC = "y";
        PROC_FS = "y";

        MODULES = "y";
        MODULE_SIG = "y";
        DEBUG_FS = "y";

        # basic networking protocols
        NET = "y";
        UNIX = "y";
        INET = "y";
        IPV6 = "y";
        PACKET = "y";           # for ppp, tcpdump ...
        SYSVIPC= "y";

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
      "earlyprintk=serial,ttyS0 console=ttyS0,115200 panic=10 oops=panic init=/bin/init loglevel=8 rootfstype=squashfs"
      "fw_devlink=off"
    ];
    users.root = {
      uid = 0; gid= 0; gecos = "Root of all evaluation";
      dir = "/";
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
      bin = dir {
        sh = symlink "${busybox}/bin/sh";
        busybox = symlink "${busybox}/bin/busybox";
      };
      dev =
        let node = type: major: minor: mode : { inherit type major minor mode; };
        in dir {
          null =    node "c" "1" "3" "0666";
          zero =    node "c" "1" "5" "0666";
          tty =     node "c" "5" "0" "0666";
          console = node "c" "5" "1" "0600";
          pts =     dir {};
        };
      etc = dir {
        profile = symlink
          (pkgs.writeScript ".profile" ''
            PATH=${lib.makeBinPath config.defaultProfile.packages}
            export PATH
          '');
      };
      proc = dir {};
      run = dir {};
      sys = dir {};
    };
  };
}
