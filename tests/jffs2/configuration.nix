{ config, pkgs, ... } :
let
  inherit (pkgs.pseudofile) dir;
in {
  imports = [
    ../../vanilla-configuration.nix
    ../../modules/outputs/squashfs.nix
    ../../modules/outputs/jffs2.nix
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
