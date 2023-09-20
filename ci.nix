{
  nixpkgs
, unstable
, liminix
, ... }:
let
  inherit (builtins) map;
  pkgs = (import nixpkgs {});
  borderVmConf =  ./bordervm.conf-example.nix;
  inherit (pkgs.lib.attrsets) genAttrs;
  devices = {
    virt = [ "qemu" ];
    hw = [ "gl-ar750" "gl-mt300n-v2" "gl-mt300a"  ];
  };
  vanilla = ./vanilla-configuration.nix;
  for-device = cfg: name:
    (import liminix {
      inherit nixpkgs borderVmConf;
      device = import (liminix + "/devices/${name}");
      liminix-config = cfg;
    }).outputs.default;
  tests = import ./tests/ci.nix;
  jobs =
    (genAttrs devices.hw (name: for-device ./vanilla-configuration-hw.nix name)) //
    (genAttrs devices.virt (name: for-device vanilla name)) //
    tests //
    {
      buildEnv = (import liminix {
        inherit nixpkgs  borderVmConf;
        device = import (liminix + "/devices/qemu");
        liminix-config = vanilla;
      }).buildEnv;
      doc = pkgs.stdenv.mkDerivation {
        name = "liminix-doc";
        nativeBuildInputs = with pkgs; [
          gnumake sphinx
          fennel luaPackages.lyaml
        ];
        src = ./doc;
        buildPhase = ''
          cat ${(import ./doc/extract-options.nix).doc} > options.json
          cat options.json | fennel --correlate parse-options.fnl > modules-generated.rst
          make html
        '';
        installPhase = ''
          mkdir -p $out/nix-support $out/share/doc/
          cp modules.rst options.json $out
          cp -a _build/html $out/share/doc/liminix
          echo "file source-dist \"$out/share/doc/liminix\"" \
              > $out/nix-support/hydra-build-products
        '';
      };
      with-unstable = (import liminix {
        nixpkgs = unstable;
        inherit borderVmConf;
        device = import (liminix + "/devices/qemu");
        liminix-config = vanilla;
      }).outputs.default;
    };
in jobs
