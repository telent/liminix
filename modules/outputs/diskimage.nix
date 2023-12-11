{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  o = config.system.outputs;
  phram_address = lib.toHexString (config.hardware.ram.startAddress + 256 * 1024 * 1024);
in {
  options.system.outputs = {
    diskimage = mkOption {
      type = types.package;
      description = ''
        diskimage
        *********

        This creates a disk image file with a partition table containing
        the contents of ``outputs.rootfs`` as its only partition.
      '';
    };
    vmdisk = mkOption {  type = types.package; };
  };

  config = {
    system.outputs = {
      diskimage =
        let
          o = config.system.outputs;
        in pkgs.runCommand "diskimage" {
          depsBuildBuild = [ pkgs.pkgsBuildBuild.util-linux ];
        } ''
          # leave 4 sectors at start for partition table
          # and alignment to 2048 bytes (does that help?)
          dd if=${o.rootfs} of=$out bs=512 seek=4 conv=sync
          echo '4,-,L,*' | sfdisk $out
        '';
      vmdisk = pkgs.runCommand "vmdisk" {} ''
        mkdir $out
        cd $out
        ln -s ${o.diskimage} ./diskimage
        cat > run.sh <<EOF
        #!${pkgs.runtimeShell}
        ${pkgs.pkgsBuildBuild.run-liminix-vm}/bin/run-liminix-vm  --arch ${pkgs.stdenv.hostPlatform.qemuArch} --u-boot ${pkgs.ubootQemuArm}/u-boot.bin --phram-address 0x${phram_address} --disk-image ${o.diskimage} /dev/null /dev/null
        EOF
        chmod +x run.sh
      '';
    };
  };
}
