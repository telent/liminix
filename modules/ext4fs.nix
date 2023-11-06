{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf mkOption types;
in
{
  imports = [
    ./initramfs.nix
  ];
  config = mkIf (config.rootfsType == "ext4") {
    kernel.config = {
      EXT4_FS = "y";
      EXT4_USE_FOR_EXT2 = "y";
      FS_ENCRYPTION = "y";
    };
    boot.initramfs.enable = true;
    system.outputs = rec {
      systemConfiguration =
        pkgs.systemconfig config.filesystem.contents;
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand e2fsprogs;
        in runCommand "mkfs.ext4" {
          depsBuildBuild = [ e2fsprogs ];
        } ''
          mkdir -p $TMPDIR/empty/nix/store/ $TMPDIR/empty/secrets
          cp ${systemConfiguration}/bin/activate $TMPDIR/empty/activate
          ln -s ${pkgs.s6-init-bin}/bin/init $TMPDIR/empty/init
          mkdir -p $TMPDIR/empty/nix/store
          for path in $(cat ${systemConfiguration}/etc/nix-store-paths) ; do
            (cd $TMPDIR/empty && cp -a $path .$path)
          done
          size=$(du -s --apparent-size --block-size 1024 $TMPDIR/empty |cut -f1)
          # add 25% for filesystem overhead
          size=$(( 5 * $size / 4))
          dd if=/dev/zero of=$out bs=1024 count=$size
          mke2fs -t ext4 -j -d $TMPDIR/empty $out
        '';
    };
  };
}
