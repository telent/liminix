{ ... }:
let
  # <nixpkgs> is set to the value designated by the nixpkgs input of the
  # jobset configuration.
  pkgs = (import <nixpkgs> {});
  device =  import <liminix/devices/qemu>;
  liminix = import <liminix> { inherit device; };
in {
  inherit (liminix.outputs) squashfs;
}
