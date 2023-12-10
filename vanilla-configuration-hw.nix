{ ... }:
{
  imports = [
    ./vanilla-configuration.nix
    ./modules/outputs/tftpboot.nix
    ./modules/outputs/kexecboot.nix
    ./modules/outputs/flashimage.nix
    ./modules/outputs/jffs2.nix
    ./modules/outputs/ubifs.nix
  ];
}
