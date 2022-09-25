{ device ? (import devices/gl-ar750.nix)
}:

let
  overlay = import ./overlay.nix;
  nixpkgs = import <nixpkgs> ( device.system // {overlays = [overlay]; });
  config = (import ./merge-modules.nix) [
    ./modules/base.nix
    ({ lib, ... } : { config = { inherit (device) kernel; }; })
    <liminix-config>
  ] nixpkgs.pkgs;
  finalConfig = config // {
    packages = (with nixpkgs.pkgs; [ s6-rc ]) ++
               config.systemPackages ++
               (builtins.attrValues config.services)
    ;
  };
  squashfs = (import ./make-image.nix) nixpkgs finalConfig;
  kernel = (import ./make-kernel.nix)  nixpkgs finalConfig.kernel.config;
in {
  outputs = {
    inherit squashfs kernel;
    default = nixpkgs.pkgs.runCommand "both-kinds" {} ''
      mkdir $out
      cd $out
      ln -s ${squashfs} squashfs
      ln -s ${kernel.vmlinux} vmlinux
   '';
  };
  # this is just here as a convenience, so that we can get a
  # cross-compiling nix-shell for any package we're customizing
  inherit (nixpkgs) pkgs;
}
