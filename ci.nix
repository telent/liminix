let
  pkgs = import <nixpkgs> { };
  liminix = <liminix>;
  borderVmConf = ./bordervm.conf-example.nix;
  inherit (pkgs.lib.attrsets) genAttrs;
  devices = [
    "gl-ar750"
    "gl-mt300a"
    "gl-mt300n-v2"
    "qemu"
    "qemu-aarch64"
    "qemu-armv7l"
    "tp-archer-ax23"
    "openwrt-one"
    "zyxel-nwa50ax"
    "turris-omnia"
    "belkin-rt3200"
  ];
  vanilla = ./vanilla-configuration.nix;
  for-device =
    name:
    (import liminix {
      inherit borderVmConf;
      device = import (liminix + "/devices/${name}");
      liminix-config = vanilla;
    }).outputs.default;
  tests = import ./tests/ci.nix;
  jobs =
    (genAttrs devices for-device)
    // tests
    // {
      buildEnv =
        (import liminix {
          inherit borderVmConf;
          device = import (liminix + "/devices/qemu");
          liminix-config = vanilla;
        }).buildEnv;
      doc = pkgs.callPackage ./doc.nix { inherit liminix borderVmConf; } ;
    };
in
jobs
// {
  all = pkgs.mkShell {
    name = "all tests";
    contents = pkgs.lib.collect pkgs.lib.isDerivation jobs;
  };
}
