{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf mkOption types;
  o = config.system.outputs;
in
{
  imports = [
    ./initramfs.nix
  ];

  options.system.outputs.rootubifs = mkOption {
    type = types.package;
    internal = true;
  };

  options.hardware.ubi = {
    minIOSize = mkOption { type = types.str; };
    logicalEraseBlockSize = mkOption { type = types.str; }; # LEB
    physicalEraseBlockSize = mkOption { type = types.str; }; # PEB
    maxLEBcount = mkOption { type = types.str; }; # LEB
  };

  config = mkIf (config.rootfsType == "ubifs") {
    kernel.config = {
      MTD_UBI="y";
      UBIFS_FS = "y";
      UBIFS_FS_SECURITY = "n";
    };
    boot.initramfs.enable = true;
    system.outputs = {
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand mtdutils;
          cfg = config.hardware.ubi;
        in runCommand "mkfs.ubifs" {
          depsBuildBuild = [ mtdutils ];
        } ''
          mkdir tmp
          tree=${o.bootablerootdir}
          mkfs.ubifs -x favor_lzo -c ${cfg.maxLEBcount} -m ${cfg.minIOSize} -e ${cfg.logicalEraseBlockSize}  -y -r $tree --output $out  --squash-uids -o $out
        '';
    };
  };
}
