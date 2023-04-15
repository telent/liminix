{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (pkgs) runCommand callPackage writeText;
in
{
  options = {
    boot.initramfs = {
      enable = mkEnableOption "enable initramfs";
      default = false;
    };
  };
  config = mkIf config.boot.initramfs.enable {
    kernel.config = {
      BLK_DEV_INITRD = "y";
      INITRAMFS_SOURCE = builtins.toJSON "${config.outputs.initramfs}";
#      INITRAMFS_COMPRESSION_LZO = "y";
    };

    outputs = {
      initramfs =
        let inherit (pkgs.pkgsBuildBuild) gen_init_cpio;
        in runCommand "initramfs.cpio" {} ''
          cat << SPECIALS | ${gen_init_cpio}/bin/gen_init_cpio /dev/stdin > $out
          dir /proc 0755 0 0
          dir /dev 0755 0 0
          nod /dev/console 0600 0 0 c 5 1
          nod /dev/mtdblock0 0600 0 0 b 31 0
          dir /target 0755 0 0
          dir /target/persist 0755 0 0
          dir /target/nix 0755 0 0
          file /init ${pkgs.preinit}/bin/preinit 0755 0 0
          SPECIALS
        '';
    };
  };
}
