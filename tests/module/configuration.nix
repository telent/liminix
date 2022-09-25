{ config, pkgs, ... } :
{
  imports = [ ./defs.nix ./module.nix ];
  config = {
    services.a.enable = true;
    services.b.enable = true;

    systemPackages = [ pkgs.hello ] ;
  };
}
