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
    virt = [ "qemu" "qemu-aarch64" "qemu-armv7l" ];
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
        inherit nixpkgs borderVmConf;
        device = import (liminix + "/devices/qemu");
        liminix-config = vanilla;
      }).buildEnv;
      doc =
        let json =
              (import liminix {
                inherit nixpkgs borderVmConf;
                device = import (liminix + "/devices/qemu");
                liminix-config = {...} : {
                  imports = [ ./modules/all-modules.nix ];
                };
              }).outputs.optionsJson;
            installers = map (f: "system.outputs.${f}") [
              "vmroot"
              "flashimage"
              "ubimage"
            ];
            inherit (pkgs.lib) concatStringsSep;
        in pkgs.stdenv.mkDerivation {
          name = "liminix-doc";
          nativeBuildInputs = with pkgs; [
            gnumake sphinx fennel luaPackages.lyaml
          ];
          src = ./.;
          buildPhase = ''
            cat ${json} | fennel --correlate doc/parse-options.fnl > doc/modules-generated.rst
            cat ${json} | fennel --correlate doc/parse-options-outputs.fnl     > doc/outputs-generated.rst
            cp ${(import ./doc/hardware.nix)} doc/hardware.rst
            make -C doc html
          '';
          installPhase = ''
            mkdir -p $out/nix-support $out/share/doc/
            cd doc
            cp *-generated.rst  $out
            ln -s ${json} $out/options.json
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
