{ device ? (import devices/gl-ar750.nix)
}:

let
  overlay = import ./overlay.nix;
  nixpkgs = import <nixpkgs> ( device.system // {overlays = [overlay]; });
  config = (import <liminix-config>) {
    config = {
      systemPackages = [];
      services = {};
    };
    tools = nixpkgs.pkgs.callPackage  ./tools {};
    inherit (nixpkgs) pkgs;
  };
  finalConfig = config // {
    packages = (with nixpkgs.pkgs; [ s6-rc ]) ++
               config.systemPackages ++
               (builtins.attrValues config.services)
    ;
  };
in (import ./make-image.nix) nixpkgs finalConfig
