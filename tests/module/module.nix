{ config, pkgs, ... } :
{
  services.z = pkgs.figlet;

  systemPackages = [ pkgs.units ] ;
}
