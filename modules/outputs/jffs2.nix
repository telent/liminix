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

  config = mkIf (config.rootfsType == "jffs2") {
    kernel.config = {
      JFFS2_FS = "y";
      JFFS2_LZO = "y";
      JFFS2_RTIME = "y";
      JFFS2_COMPRESSION_OPTIONS = "y";
      JFFS2_ZLIB = "y";
      JFFS2_CMODE_SIZE = "y";
    };
    boot.initramfs.enable = true;
    system.outputs = {
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand mtdutils;
          endian = if pkgs.stdenv.isBigEndian then "--big-endian" else "--little-endian";
        in
        runCommand "make-jffs2"
          {
            depsBuildBuild = [ mtdutils ];
          }
          ''
            tree=${o.bootablerootdir}
            (cd $tree && mkfs.jffs2 --compression-mode=size ${endian} -e ${toString config.hardware.flash.eraseBlockSize} --enable-compressor=lzo --pad --root . --output $out --squash --faketime )
          '';
    };
  };
}
