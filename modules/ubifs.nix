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
    system.outputs = {
      systemConfiguration =
        pkgs.systemconfig config.filesystem.contents;
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand mtdutils;
          cfg = config.hardware.ubi;
        in runCommand "mkfs.ubifs" {
          depsBuildBuild = [ mtdutils ];
        } ''
          mkdir tmp
          cp -a ${o.rootfsFiles} tmp
          ${if config.boot.loader.extlinux.enable
            then "(cd tmp && ln -s ${o.extlinux} boot)"
            else ""
           }
          mkfs.ubifs -x favor_lzo -c ${cfg.maxLEBcount} -m ${cfg.minIOSize} -e ${cfg.eraseBlockSize}  -y -r tmp --output $out  --squash-uids -o $out
        '';
    };
  };
}
