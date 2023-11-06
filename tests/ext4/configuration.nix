{ config, pkgs, lib, ... } :
let
  inherit (pkgs.pseudofile) dir symlink;
in {
  imports = [
    ../../vanilla-configuration.nix
    ../../modules/squashfs.nix
    ../../modules/ext4fs.nix
  ];
  config.rootfsType = "ext4";
  config.filesystem = dir {
    hello = {
      type = "f";
      uid = 7;
      gid = 24;
      file = "hello world";
    };
  };
}
