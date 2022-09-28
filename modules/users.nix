{ lib, pkgs, config, ...}:
let
  inherit (lib) concatStrings concatStringsSep mapAttrsToList; # mkEnableOption mkOption types isDerivation isType hasAttr ;
  inherit (builtins) toString;
  inherit (pkgs.pseudofile) dir symlink;
#  inherit (pkgs) busybox;
  passwd-file  =
    let lines =  mapAttrsToList (name: u: "${name}:${if u ? passwd  then u.passwd else "!!"}:${toString u.uid}:${toString u.gid}:${u.gecos}:${u.dir}:${u.shell}\n" )
      config.users;
    in concatStrings lines;
  group-file =
    let lines = mapAttrsToList
      (name: {gid, usernames ? []}:
        "${name}:x:${toString gid}:${concatStringsSep "," usernames}\n" )
      config.groups;
    in concatStrings lines;
in {
  config = {
    filesystem = dir {
      etc = dir {
        passwd = { file = passwd-file; };
        group = { file = group-file; };
      };
    };
  };
}
