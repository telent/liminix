{
  device
, liminix-config ? <liminix-config>
, nixpkgs ? <nixpkgs>
, borderVmConf ? ./bordervm.conf.nix
}:

let
  overlay = import ./overlay.nix;
  pkgs = import nixpkgs (device.system // {
    overlays = [overlay];
    config = {
      allowUnsupportedSystem = true; # mipsel
      permittedInsecurePackages = [
        "python-2.7.18.6"       # kernel backports needs python <3
      ];
    };
  });

  config = (pkgs.lib.evalModules {
    modules = [
      { _module.args = { inherit pkgs; lib = pkgs.lib; }; }
      ./modules/hardware.nix
      ./modules/base.nix
      ./modules/busybox.nix
      ./modules/hostname.nix
      device.module
      liminix-config
      ./modules/s6
      ./modules/users.nix
      ./modules/outputs.nix
    ];
  }).config;

  borderVm = ((import <nixpkgs/nixos/lib/eval-config.nix>) {
    system = builtins.currentSystem;
    modules = [
      ({  ... } : { nixpkgs.overlays = [ overlay ]; })
      (import ./bordervm-configuration.nix)
      borderVmConf
    ];
  }).config.system;
in {
  outputs = config.outputs // {
    default = config.outputs.${config.hardware.defaultOutput};
  };

  # this is just here as a convenience, so that we can get a
  # cross-compiling nix-shell for any package we're customizing
  inherit pkgs;

  buildEnv = pkgs.mkShell {
    packages = with pkgs.pkgsBuildBuild; [
      tufted
      routeros.routeros
      routeros.ros-exec-script
      mips-vm
      borderVm.build.vm
      go-l2tp
      min-copy-closure
    ];
  };
}
