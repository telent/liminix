{
  deviceName ? null
, device ? (import ./devices/${deviceName} )
, liminix-config ? <liminix-config>
, nixpkgs ? <nixpkgs>
, borderVmConf ? ./bordervm.conf.nix
, imageType ? "primary"
}:

let
  overlay = import ./overlay.nix;
  pkgs = import nixpkgs (device.system // {
    overlays = [overlay];
    config = {
      allowUnsupportedSystem = true; # mipsel
      permittedInsecurePackages = [
        "python-2.7.18.6"       # kernel backports needs python <3
        "python-2.7.18.7"
      ];
    };
  });

  evalModules = (import ./lib/eval-config.nix {
    inherit nixpkgs pkgs;
    inherit (pkgs) lib;
  });

  eval = evalModules {
    modules = [
      device.module
      liminix-config
      {
        boot.imageType = imageType;
      }
    ];
  };

  config = eval.config;

  borderVm = ((import <nixpkgs/nixos/lib/eval-config.nix>) {
    system = builtins.currentSystem;
    modules = [
      ({  ... } : { nixpkgs.overlays = [ overlay ]; })
      (import ./bordervm-configuration.nix)
      borderVmConf
    ];
  }).config.system;
in {
  inherit evalModules;

  outputs = config.system.outputs // {
    default = config.system.outputs.${config.hardware.defaultOutput};
    optionsJson =
      let o = import ./doc/extract-options.nix {
            inherit pkgs eval;
            lib = pkgs.lib;
          };
      in pkgs.writeText "options.json" (builtins.toJSON o);
  };

  # this is just here as a convenience, so that we can get a
  # cross-compiling nix-shell for any package we're customizing
  inherit pkgs;

  buildEnv = pkgs.mkShell {
    packages = with pkgs.pkgsBuildBuild; [
      tufted
      routeros.routeros
      routeros.ros-exec-script
      run-liminix-vm
      borderVm.build.vm
      go-l2tp
      min-copy-closure
      fennelrepl
      lzma
      lua
    ];
  };
}
