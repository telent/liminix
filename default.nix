{ device ? (import devices/gl-ar750.nix)
}:

let
  overlay = import ./overlay.nix;
  nixpkgs = import <nixpkgs> ( device.system // {overlays = [overlay]; });
  inherit (nixpkgs.pkgs) callPackage writeText liminix;
  config = (import ./merge-modules.nix) [
    ./modules/base.nix
    ({ lib, ... } : { config = { inherit (device) kernel; }; })
    <liminix-config>
    ./modules/s6
    ./modules/users.nix
  ] nixpkgs.pkgs;
  squashfs = liminix.builders.squashfs config.filesystem.contents;
  kernel = callPackage ./kernel {
    inherit (config.kernel) config;
  };
in {
  outputs = {
    inherit squashfs kernel;
    default = nixpkgs.pkgs.runCommand "both-kinds" {} ''
      mkdir $out
      cd $out
      ln -s ${squashfs} squashfs
      ln -s ${kernel.vmlinux} vmlinux
   '';
    # this exists so that you can run "nix-store -q --tree" on it and find
    # out what's in the image, which is nice if it's unexpectedly huge
    manifest = writeText "manifest.json" (builtins.toJSON config.filesystem.contents);
  };
  # this is just here as a convenience, so that we can get a
  # cross-compiling nix-shell for any package we're customizing
  inherit (nixpkgs) pkgs;
}
