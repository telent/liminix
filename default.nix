{
  deviceName ? null,
  device ? (import ./devices/${deviceName}),
  liminix-config ? <liminix-config>,
  borderVmConf ? ./bordervm.conf.nix,
  imageType ? "primary",
}:

let
  overlay = import ./overlay.nix;
  pkgs = import <nixpkgs> (
    device.system
    // {
      overlays = [ overlay ];
      config = {
        allowUnsupportedSystem = true; # mipsel
        permittedInsecurePackages = [
          "python-2.7.18.6" # kernel backports needs python <3
          "python-2.7.18.7"
        ];
      };
    }
  );

  eval = pkgs.lib.evalModules {
    specialArgs = {
      modulesPath = builtins.toString ./modules;
    };
    modules = [
      {
        _module.args = {
          inherit pkgs;
          inherit (pkgs) lim;
        };
      }
      ./modules/hardware.nix
      ./modules/base.nix
      ./modules/busybox.nix
      ./modules/hostname.nix
      ./modules/kernel
      ./modules/logging.nix
      ./modules/klogd.nix
      device.module
      liminix-config
      ./modules/s6
      ./modules/users.nix
      ./modules/outputs.nix
      {
        boot.imageType = imageType;
      }
    ];
  };
  config = eval.config;

  borderVm =
    ((import <nixpkgs/nixos/lib/eval-config.nix>) {
      system = builtins.currentSystem;
      modules = [
        {
          nixpkgs.overlays = [
            (final: prev: {
              go-l2tp = final.callPackage ./pkgs/go-l2tp { };
              tufted = final.callPackage ./pkgs/tufted { };
            })
          ];
        }
        (import ./bordervm-configuration.nix)
        borderVmConf
      ];
    }).config.system;
in
{
  outputs = config.system.outputs // {
    default = config.system.outputs.${config.hardware.defaultOutput};
    optionsJson =
      let
        o = import ./doc/extract-options.nix {
          inherit pkgs eval;
          lib = pkgs.lib;
        };
      in
      pkgs.writeText "options.json" (builtins.toJSON o);
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
