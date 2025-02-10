let
  img =
    (import <liminix> {
      device = import <liminix/devices/qemu-armv7l>;
      liminix-config = ./configuration.nix;
    }).outputs.default;
  pkgs = import <nixpkgs> { overlays = [ (import ../../overlay.nix) ]; };
in
pkgs.runCommand "check"
  {
    nativeBuildInputs = with pkgs; [
      expect
      socat
    ];
  }
  ''
    . ${../test-helpers.sh}

    mkdir vm
    ${img}/run.sh --background ./vm
    expect ${./wait-for-wlan.expect} |tee output && mv output $out
  ''
