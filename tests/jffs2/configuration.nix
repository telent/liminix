{ config, pkgs, lib, ... } :
{
  imports = [
    ../../vanilla-configuration.nix
    ../../modules/jffs2.nix
  ];
  config.rootfsType = "jffs2";
}
