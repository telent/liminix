let
  nixpkgs = <nixpkgs>;
  liminix = (import ./default.nix {
    device = (import ./devices/qemu);
    liminix-config = ./vanilla-configuration.nix;
    inherit nixpkgs;
  });
in liminix
