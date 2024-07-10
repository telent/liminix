{
  nixpkgs,
  unstable,
  liminix,
  ...
}:
let
  pkgs = (import nixpkgs { });
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
    "zyxel-nwa50ax"
  ];
  vanilla = ./vanilla-configuration.nix;
  for-device = name:
    (import liminix {
      inherit nixpkgs borderVmConf;
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
          inherit nixpkgs borderVmConf;
          device = import (liminix + "/devices/qemu");
          liminix-config = vanilla;
        }).buildEnv;
      doc =
        let
          json =
            (import liminix {
              inherit nixpkgs borderVmConf;
              device = import (liminix + "/devices/qemu");
              liminix-config =
                { ... }:
                {
                  imports = [ ./modules/all-modules.nix ];
                };
            }).outputs.optionsJson;
        in
        pkgs.stdenv.mkDerivation {
          name = "liminix-doc";
          nativeBuildInputs = with pkgs; [
            gnumake
            sphinx
            fennel
            luaPackages.lyaml
          ];
          src = ./.;
          buildPhase = ''
            cat ${json} | fennel --correlate doc/parse-options.fnl > doc/modules-generated.inc.rst
            cat ${json} | fennel --correlate doc/parse-options-outputs.fnl     > doc/outputs-generated.inc.rst
            cp ${(import ./doc/hardware.nix)} doc/hardware.rst
            make -C doc html
          '';
          installPhase = ''
            mkdir -p $out/nix-support $out/share/doc/
            cd doc
            cp *-generated.inc.rst hardware.rst $out
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
