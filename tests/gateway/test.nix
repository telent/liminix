let
  img =
    (import <liminix> {
      device = import <liminix/devices/gl-ar750>;
      liminix-config = <liminix/examples/rotuer.nix>;
    }).outputs.default;
  pkgs = import <nixpkgs> { overlays = [ (import ../../overlay.nix) ]; };
in img
