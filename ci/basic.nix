{
  nixpkgs
, deviceName
, ... }:
let
  pkgs = (import nixpkgs {});
  device =  import "${<liminix/devices>}/${deviceName}";
  liminix-config = import <liminix/tests/smoke/configuration.nix>;
  liminix = import <liminix> { inherit device liminix-config; };
in {
  inherit (liminix.outputs) squashfs kernel default manifest;
}
