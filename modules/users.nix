{ lib, pkgs, config, ...}:
let
  inherit (lib)
    concatStrings concatStringsSep mapAttrsToList mkOption types;
  inherit (builtins) toString;
  inherit (pkgs.pseudofile) dir symlink;
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
  options = {
    users =  mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          passwd = mkOption {
            type = types.str;
            default = "!!";
          };
          uid = mkOption {
            type = types.int;
          };
          gid = mkOption {
            type = types.int;
          };
          gecos = mkOption {
            type = types.str;
            default = "";
            example = "Jo Q User";
          };
          dir = mkOption {
            type = types.str;
            default = "/run";
          };
          shell = mkOption {
            type = types.str;
            default = "/bin/sh";
          };
          openssh.authorizedKeys.keys = mkOption {
            type = types.listOf types.str;
            default = [];
          };
        };
      });
    };
    groups =  mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          gid = mkOption {
            type = types.int;
          };
          usernames = mkOption {
            type = types.listOf types.str;
            default = [];
          };
        };
      });
    };
  };
  config =
    let authorized_key_files =
          lib.attrsets.mapAttrs
            (name: val: dir {
              ".ssh" = dir {
                authorized_keys = {
                  type = "f";
                  mode = "0400";
                  file = lib.concatStringsSep
                    "\n" val.openssh.authorizedKeys.keys;
                };
              };
            })
            config.users;
    in {
      filesystem = dir {
        etc = dir {
          passwd = { file = passwd-file; };
          group = { file = group-file; };
        };
        home = dir authorized_key_files;
      };
    };
}
