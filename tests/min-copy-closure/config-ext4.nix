{ lib, ... } :
{
  imports= [
    ./configuration.nix
    ../../modules/outputs/ext4fs.nix
  ];
  rootfsType = lib.mkForce "ext4";
}
