{ ... }:
let
  # <nixpkgs> is set to the value designated by the nixpkgs input of the
  # jobset configuration.
  pkgs = (import <nixpkgs> {});
  device =  import <liminix/devices/qemu>;
  liminix-config = import <liminix/tests/smoke/configuration.nix>;
  liminix = import <liminix> { inherit device liminix-config; };
in {
  inherit (liminix.outputs) squashfs kernel default manifest;
}
