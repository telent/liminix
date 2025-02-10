{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  inherit (pkgs) runCommand;
in
{
  imports = [ ./system-configuration.nix ];
  options = {
    boot.initramfs = {
      enable = mkEnableOption "initramfs";
    };
    system.outputs = {
      initramfs = mkOption {
        type = types.package;
        internal = true;
        description = ''
          Initramfs image capable of mounting the real root
          filesystem
        '';
      };
    };
  };
  config = mkIf config.boot.initramfs.enable {
    kernel.config = {
      BLK_DEV_INITRD = "y";
      INITRAMFS_SOURCE = builtins.toJSON "${config.system.outputs.initramfs}";
      #      INITRAMFS_COMPRESSION_LZO = "y";
    };

    system.outputs = {
      initramfs =
        let
          inherit (pkgs.pkgsBuildBuild) gen_init_cpio;
        in
        runCommand "initramfs.cpio" { } ''
          cat << SPECIALS | ${gen_init_cpio}/bin/gen_init_cpio /dev/stdin > $out
          dir /proc 0755 0 0
          dir /dev 0755 0 0
          nod /dev/console 0600 0 0 c 5 1
          dir /target 0755 0 0
          dir /target/persist 0755 0 0
          dir /target/nix 0755 0 0
          file /init ${pkgs.preinit}/bin/preinit 0755 0 0
          SPECIALS
        '';
    };
  };
}
