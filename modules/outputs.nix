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
  imports = [
    ./squashfs.nix
  ];
  options = {
    system.outputs = {
      kernel = mkOption {
        type = types.package;
        description = ''
          Kernel vmlinux file (usually ELF)
        '';
      };
      dtb = mkOption {
        type = types.package;
        description = ''
          Compiled device tree (FDT) for the target device
        '';
      };
      uimage = mkOption {
        type = types.package;
        description = ''
          Combined kernel and FDT in uImage (U-Boot compatible) format
        '';
      };
      vmroot = mkOption {
        type = types.package;
        description = ''
          Directory containing separate kernel and rootfs image for
          use with qemu (see run-liminix-vm)
        '';
      };
      manifest = mkOption {
        type = types.package;
        description = ''
          Debugging aid. JSON rendition of config.filesystem, on
          which can run "nix-store -q --tree" on it and find
          out what's in the image, which is nice if it's unexpectedly huge
        '';
      };
      rootfs = mkOption {
        type = types.package;
        description = ''
          root filesystem (squashfs or jffs2) image
        '';
        internal = true;
      };
    };
  };
  config = {
    system.outputs = rec {
      # tftpd = pkgs.buildPackages.tufted;
      kernel = liminix.builders.kernel.override {
        inherit (config.kernel) config src extraPatchPhase;
      };
      dtb = liminix.builders.dtb {
        inherit (config.boot) commandLine;
        dts = config.hardware.dts.src;
        includes = config.hardware.dts.includes ++ [
          "${kernel.headers}/include"
        ];
      };
      uimage = liminix.builders.uimage {
        commandLine = concatStringsSep " " config.boot.commandLine;
        inherit (config.hardware) loadAddress entryPoint;
        inherit (config.boot) imageFormat;
        inherit kernel;
        inherit dtb;
      };
      # could use trivial-builders.linkFarmFromDrvs here?
      vmroot =
        let
          cmdline = builtins.toJSON (concatStringsSep " " config.boot.commandLine);
          makeBootableImage = pkgs.runCommandCC "objcopy" {}
            (if pkgs.stdenv.hostPlatform.isAarch
             then "${pkgs.stdenv.cc.targetPrefix}objcopy -O binary -R .comment -S ${kernel} $out"
             else "cp ${kernel} $out");
        in pkgs.runCommandCC "vmroot" {} ''
          mkdir $out
          cd $out
          ln -s ${config.system.outputs.rootfs} rootfs
          ln -s ${kernel} vmlinux
          ln -s ${manifest} manifest
          ln -s ${kernel.headers} build
          echo ${cmdline} > commandline
          cat > run.sh << EOF
          #!${pkgs.runtimeShell}
          CMDLINE=${cmdline} ${pkgs.pkgsBuildBuild.run-liminix-vm}/bin/run-liminix-vm --arch ${pkgs.stdenv.hostPlatform.qemuArch} \$* ${makeBootableImage} ${config.system.outputs.rootfs}
          EOF
          chmod +x run.sh
       '';

      manifest = writeText "manifest.json" (builtins.toJSON config.filesystem.contents);
    };
  };
}
