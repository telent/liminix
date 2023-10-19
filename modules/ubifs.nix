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
  options.hardware.ubi = {
    minIOSize = mkOption { type = types.str; };
    eraseBlockSize = mkOption { type = types.str; }; # LEB
    maxLEBcount = mkOption { type = types.str; }; # LEB
  };

  config = mkIf (config.rootfsType == "ubifs") {
    kernel.config = {
      MTD_UBI="y";

      UBIFS_FS = "y";
      UBIFS_FS_SECURITY = "n";
    };
    boot.initramfs.enable = true;
    system.outputs = rec {
      systemConfiguration =
        pkgs.systemconfig config.filesystem.contents;
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand mtdutils;
          cfg = config.hardware.ubi;
        in runCommand "mkfs.ubifs" {
          depsBuildBuild = [ mtdutils ];
        } ''
          mkdir -p $TMPDIR/empty/nix/store/ $TMPDIR/empty/secrets
          cp ${systemConfiguration}/bin/activate $TMPDIR/empty/activate
          ln -s ${pkgs.s6-init-bin}/bin/init $TMPDIR/empty/init
          mkdir -p $TMPDIR/empty/nix/store
          for path in $(cat ${systemConfiguration}/etc/nix-store-paths) ; do
            (cd $TMPDIR/empty && cp -a $path .$path)
          done
          mkfs.ubifs -x favor_lzo -c ${cfg.maxLEBcount} -m ${cfg.minIOSize} -e ${cfg.eraseBlockSize}  -y -r $TMPDIR/empty --output $out  --squash-uids -o $out
        '';
    };
  };
}
