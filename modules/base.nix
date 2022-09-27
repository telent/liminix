{ lib, pkgs, ...}:
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
    systemPackages = mkOption {
      type = types.listOf types.package;
    };
    services = mkOption {
      type = types.attrsOf type_service;
    };
    environment = mkOption { type = types.anything; };
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
  };
  config = {
    environment = dir {
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
            PATH=${lib.makeBinPath (with pkgs; [ s6-init-bin busybox execline s6-linux-init s6-rc])}
            export PATH
          '');
        passwd = { file = "root::0:0:root:/:/bin/sh\n"; };
        group = { file = "root::0:\n"; };
      };
      proc = dir {};
      run = dir {};
      sys = dir {};
    };
  };
}
