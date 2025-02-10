{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  o = config.system.outputs;
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
    system.outputs = {
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand e2fsprogs;
        in
        runCommand "mkfs.ext4"
          {
            depsBuildBuild = [ e2fsprogs ];
          }
          ''
            tree=${o.bootablerootdir}
            size=$(du -s --apparent-size --block-size 1024 $tree |cut -f1)
            # add 25% for filesystem overhead
            size=$(( 5 * $size / 4))
            dd if=/dev/zero of=$out bs=1024 count=$size
            mke2fs -t ext4 -j -d $tree $out
          '';
    };
  };
}
