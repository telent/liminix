{ pkgs, ... } :
{
  imports= [./config-ext4.nix];
  defaultProfile.packages = with pkgs; [
    figlet
  ];
}
