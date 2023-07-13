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
  options.system.outputs = {
    systemConfiguration = mkOption {
      type = types.package;
      description = ''
        pkgs.systemconfig for the configured filesystem,
        contains 'activate' and 'init' commands
      '';
      internal = true;
    };
  };

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
    system.outputs = rec {
      systemConfiguration =
        pkgs.systemconfig config.filesystem.contents;
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand mtdutils;
          endian = if pkgs.stdenv.isBigEndian
                   then "--big-endian" else "--little-endian";
        in runCommand "make-jffs2" {
          depsBuildBuild = [ mtdutils ];
        } ''
          mkdir -p $TMPDIR/empty/nix/store/ $TMPDIR/empty/secrets
          cp ${systemConfiguration}/bin/activate $TMPDIR/empty/activate
          ln -s ${pkgs.s6-init-bin}/bin/init $TMPDIR/empty/init
          grafts=$(sed < ${systemConfiguration}/etc/nix-store-paths 's/^\(.*\)$/--graft \1:\1/g')
          mkfs.jffs2 --compression-mode=size ${endian} -e ${config.hardware.flash.eraseBlockSize} --enable-compressor=lzo --pad --root $TMPDIR/empty --output $out  $grafts --squash --faketime
        '';
    };
  };
}
