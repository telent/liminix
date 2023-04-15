{ config, pkgs, lib, ... } :
let
  inherit (pkgs.pseudofile) dir symlink;
in {
  imports = [
    ../../vanilla-configuration.nix
    ../../modules/squashfs.nix
    ../../modules/jffs2.nix
  ];
  config.rootfsType = "jffs2";
  config.filesystem = dir {
    hello = {
      type = "f";
      uid = 7;
      gid = 24;
      file = "hello world";
    };
  };
}
