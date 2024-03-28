{ pkgs, ... } :
{
  imports= [./config-ext4.nix];
  defaultProfile.packages = with pkgs; [
    figlet
  ];
  services.ripvanwinkle = pkgs.liminix.services.longrun {
    name = "winkle";
    run = ''
      echo SLEEPING > /dev/console
      sleep 3600
    '';
  };
}
