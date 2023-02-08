{
  nixpkgs
, unstable
, liminix
, ... }:
let
  inherit (builtins) map;
  pkgs = (import nixpkgs {});
  inherit (pkgs.lib.attrsets) genAttrs;
  devices = [ "qemu" "gl-ar750" "gl-mt300n-v2" "gl-mt300a" ];
  vanilla = ./vanilla-configuration.nix;
  for-device = name:
    (import liminix {
      inherit nixpkgs;
      device = import (liminix + "/devices/${name}");
      liminix-config = vanilla;
    }).outputs.default;
  tests = import ./tests/ci.nix;
  jobs =
    (genAttrs devices (name: for-device name)) // tests // {
      buildEnv = (import liminix {
        inherit nixpkgs;
        device = import (liminix + "/devices/qemu");
        liminix-config = vanilla;
      }).buildEnv;
      with-unstable = (import liminix {
        nixpkgs = unstable;
        device = import (liminix + "/devices/qemu");
        liminix-config = vanilla;
      }).outputs.default;
    };
in builtins.trace jobs jobs
