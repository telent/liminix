{ device ? (import devices/gl-ar750.nix)
}:

let
  overlay = import ./overlay.nix;
  nixpkgs = import <nixpkgs> ( device.system // {overlays = [overlay]; });
  inherit (nixpkgs.pkgs) callPackage writeText liminix;
  inherit (nixpkgs.lib) concatStringsSep;
  config = (import ./merge-modules.nix) [
    ./modules/base.nix
    ({ lib, ... } : { config = { inherit (device) kernel; }; })
    <liminix-config>
    ./modules/s6
    ./modules/users.nix
  ] nixpkgs.pkgs;
  squashfs = liminix.builders.squashfs config.filesystem.contents;
  kernel = callPackage ./kernel {
    inherit (config.kernel) config checkedConfig;
  };

  outputs = rec {
    inherit squashfs kernel;
    dtb =  kernel.dtb {
      dts = "qca9531_glinet_gl-ar750.dts";

    };
    uimage = kernel.uimage {
      commandLine = concatStringsSep " " config.boot.commandLine;
      inherit (device.boot) loadAddress entryPoint;
      inherit (kernel) vmlinux;
      inherit dtb;
    };
    combined-image = nixpkgs.pkgs.runCommand "firmware.bin" {
      nativeBuildInputs = [ nixpkgs.buildPackages.ubootTools ];
    } ''
      mkdir $out
      dd if=${uimage} of=$out/firmware.bin bs=128k conv=sync
      dd if=${squashfs} of=$out/firmware.bin bs=128k conv=sync,nocreat,notrunc oflag=append
    '';
    directory = nixpkgs.pkgs.runCommand "both-kinds" {} ''
       mkdir $out
       cd $out
       ln -s ${squashfs} squashfs
       ln -s ${kernel.vmlinux} vmlinux
    '';
    # this exists so that you can run "nix-store -q --tree" on it and find
    # out what's in the image, which is nice if it's unexpectedly huge
    manifest = writeText "manifest.json" (builtins.toJSON config.filesystem.contents);
    tftpd = nixpkgs.pkgs.buildPackages.tufted;
  };
in {
  outputs = outputs // { default = outputs.${device.outputs.default}; };

  # this is just here as a convenience, so that we can get a
  # cross-compiling nix-shell for any package we're customizing
  inherit (nixpkgs) pkgs;
}
