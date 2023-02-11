{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  inherit (pkgs) liminix callPackage writeText;
in
{
  options = {
    outputs = mkOption {
      type = types.attrsOf types.package;
      default = {};
    };
  };
  config = {
    outputs = rec {
      squashfs = liminix.builders.squashfs config.filesystem.contents;
      tftpd = pkgs.buildPackages.tufted;
      kernel = liminix.builders.kernel.override {
        inherit (config.kernel) config src extraPatchPhase;
      };
      dtb =  (callPackage ../kernel/dtb.nix {}) {
        dts = config.kernel.dts.src;
        includes = config.kernel.dts.includes ++ [
          "${kernel.headers}/include"
        ];
      };
      uimage = (callPackage ../kernel/uimage.nix {}) {
        commandLine = concatStringsSep " " config.boot.commandLine;
        inherit (config.device) loadAddress entryPoint;
        inherit kernel;
        inherit dtb;
      };
      combined-image = pkgs.runCommand "firmware.bin" {
        nativeBuildInputs = [ pkgs.buildPackages.ubootTools ];
      } ''
        mkdir $out
        dd if=${uimage} of=$out/firmware.bin bs=128k conv=sync
        dd if=${squashfs} of=$out/firmware.bin bs=128k conv=sync,nocreat,notrunc oflag=append
      '';

      vmroot = pkgs.runCommand "qemu" {} ''
        mkdir $out
        cd $out
        ln -s ${squashfs} squashfs
        ln -s ${kernel} vmlinux
        ln -s ${manifest} manifest
        ln -s ${kernel.headers} build
      '';

      # this exists so that you can run "nix-store -q --tree" on it and find
      # out what's in the image, which is nice if it's unexpectedly huge
      manifest = writeText "manifest.json" (builtins.toJSON config.filesystem.contents);
    };
  };
}
