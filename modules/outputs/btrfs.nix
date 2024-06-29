{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf;
  o = config.system.outputs;
in
{
  imports = [
    ./initramfs.nix
  ];
  config = mkIf (config.rootfsType == "btrfs") {
    kernel.config = {
      BTRFS_FS = "y";
    };
    boot.initramfs.enable = true;
    system.outputs = {
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand e2fsprogs;
        in runCommand "mkfs.btrfs" {
          depsBuildBuild = [ e2fsprogs ];
        } ''
          tree=${o.bootablerootdir}
          size=$(du -s --apparent-size --block-size 1024 $tree |cut -f1)
          # add 25% for filesystem overhead
          size=$(( 5 * $size / 4))
          dd if=/dev/zero of=$out bs=1024 count=$size
          echo "not implemented" ; exit 1
          # mke2fs -t ext4 -j -d $tree $out
        '';
    };
  };
}
