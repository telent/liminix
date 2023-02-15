{
  device
, liminix-config ? <liminix-config>
, nixpkgs ? <nixpkgs>
}:

let
  overlay = import ./overlay.nix;
  pkgs = import nixpkgs (device.system // {
    overlays = [overlay];
    config = {allowUnsupportedSystem = true; };
  });

  config = (import ./lib/merge-modules.nix) [
    ./modules/base.nix
    device.module
    liminix-config
    ./modules/s6
    ./modules/users.nix
    ./modules/outputs.nix
  ] pkgs;

  borderVm = ((import <nixpkgs/nixos/lib/eval-config.nix>) {
    system = builtins.currentSystem;
    modules = [
      ({  ... } : { nixpkgs.overlays = [ overlay ]; })
      (import ./bordervm-configuration.nix)
    ];
  }).config.system;
in {
  outputs = config.outputs // {
    default = config.outputs.${config.device.defaultOutput};
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
    ];
  };
}
