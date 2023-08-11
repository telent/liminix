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
  imports = [
    ./kernel.nix                # this is a separate module for doc purposes
  ];
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
