{ lib, pkgs, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;

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
      etc = dir {
        profile = symlink
          (pkgs.writeScript ".profile" ''
            PATH=${lib.makeBinPath (with pkgs; [ s6-init-bin busybox execline s6-linux-init s6-rc])}
            export PATH
          '');
        passwd = { file = "root::0:0:root:/:/bin/sh\n"; };
        group = { file = "root::0:\n"; };
      };
    };
  };
}
