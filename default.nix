{ device ? (import devices/gl-ar750.nix)
}:

let
  overlay = import ./overlay.nix;
  nixpkgs = import <nixpkgs> ( device.system // {overlays = [overlay]; });
  config = (import ./merge-modules.nix) [
    (import ./modules/base.nix { inherit device; })
    <liminix-config>
  ] nixpkgs.pkgs;
  finalConfig = config // {
    packages = (with nixpkgs.pkgs; [ s6-rc ]) ++
               config.systemPackages ++
               (builtins.attrValues config.services)
    ;
  };
  squashfs = (import ./make-image.nix) nixpkgs finalConfig;
  kernel = (import ./make-kernel.nix)  nixpkgs finalConfig;
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
}
