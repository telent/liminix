{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  inherit (pkgs) liminix writeText;
  o = config.system.outputs;
in
{
  imports = [
    ./outputs/squashfs.nix
    ./outputs/jffs2.nix
    ./outputs/vmroot.nix
    ./outputs/boot-extlinux.nix
    ./outputs/boot-fit.nix
    ./outputs/uimage.nix
    ./outputs/updater
    ./outputs/ubimage.nix
#    ./outputs/mtdimage.nix
  ];
  options = {
    system.outputs = {
      # the convention here is to mark an output as "internal" if
      # it's not a complete system (kernel plus userland, or installer)
      # but only part of one.
      kernel = mkOption {
        type = types.package;
        internal = true;
        description = ''
          kernel
          ******

          Kernel package (multi-output derivation)
        '';
      };
      dtb = mkOption {
        type = types.package;
        internal = true;
        description = ''
          dtb
          ***

          Compiled device tree (FDT) for the target device
        '';
      };
      tplink-safeloader = mkOption {
        type = types.package;
      };
      u-boot = mkOption {
        type = types.package;
      };
      manifest = mkOption {
        type = types.package;
        internal = true;
        description = ''
          Debugging aid. JSON rendition of config.filesystem, on
          which can run "nix-store -q --tree" on it and find
          out what's in the image, which is nice if it's unexpectedly huge
        '';
      };
      rootdir = mkOption {
        type = types.package;
        internal = true;
        description = ''
          directory of files to package into root filesystem
        '';
      };
      bootfiles = mkOption {
        type = types.nullOr types.package;
        internal = true;
        default = null;
        # description = "";
      };
      bootablerootdir = mkOption {
        type = types.package;
        internal = true;
        description = ''
          directory of files to package into root filesystem, including
          a kernel and appropriate associated gubbins for the
          selected bootloader
        '';
      };
      rootfs = mkOption {
        type = types.package;
        internal = true;
        description = ''
          root filesystem (squashfs or jffs2) image
        '';
      };
    };
  };
  config = {
    system.outputs = rec {
      dtb = liminix.builders.dtb {
        inherit (config.boot) commandLine;
        dts = [config.hardware.dts.src] ++ config.hardware.dts.includes;
        includes = config.hardware.dts.includePaths ++ [
          "${o.kernel.headers}/include"
        ];
      };
      rootdir =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand;
        in runCommand "mktree" { } ''
          mkdir -p $out/nix/store/ $out/secrets $out/boot
          cp ${o.systemConfiguration}/bin/activate $out/activate
          ln -s ${pkgs.s6-init-bin}/bin/init $out/init
          mkdir -p $out/nix/store
          for path in $(cat ${o.systemConfiguration}/etc/nix-store-paths) ; do
            (cd $out && cp -a $path .$path)
          done
        '';
      bootablerootdir =
        let inherit (pkgs.pkgsBuildBuild) runCommand;
        in runCommand "add-slash-boot" { } ''
          cp -a ${o.rootdir} $out
          ${if o.bootfiles != null
            then "(cd $out && chmod -R +w . && rmdir boot && cp -a ${o.bootfiles} boot)"
            else ""
           }
         '';
      manifest = writeText "manifest.json" (builtins.toJSON config.filesystem.contents);
    };
  };
}
