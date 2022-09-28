{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) busybox;

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
      config = mkOption {
        # mostly the values are y n or m, but sometimes
        # other strings are also used
        type = types.attrsOf types.nonEmptyStr;
      };
      checkedConfig = mkOption {
        type = types.attrsOf types.nonEmptyStr;
      };
    };
    groups =  mkOption {
      type = types.attrsOf types.anything;
    };
    users =  mkOption {
      type = types.attrsOf types.anything;
    };
  };
  config = {
    defaultProfile.packages = with pkgs;
      [ s6-init-bin busybox execline s6-linux-init s6-rc ];

    users.root = {
      uid = 0; gid= 0; gecos = "Root of all evaluation";
      dir = "/";
      passwd = "";
      shell = "/bin/sh";
    };
    groups.root = {
      gid = 0; usernames = ["root"];
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
