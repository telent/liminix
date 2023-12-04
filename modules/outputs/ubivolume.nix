{
  config
, pkgs
, lib
, ...
}:
let
  inherit (pkgs) liminix;
  inherit (lib) mkIf mkOption types concatStringsSep optionalString;
in
  {
    imports = [
      ./initramfs.nix
      ./ubifs.nix
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

      system.outputs.rootfs =
      let
        inherit (pkgs.pkgsBuildBuild) runCommand;
        ubiVolume = ({ name, volumeId, image, flags ? [] }:
        ''
          [${name}]
          mode=ubi
          vol_id=${toString volumeId}
          vol_type=dynamic
          vol_name=${name}
          vol_alignment=1
          ${optionalString (image != null) ''
            image=${image}
          ''}
          ${optionalString (image == null) ''
            vol_size=1MiB
          ''}
          ${optionalString (flags != []) ''
            vol_flags=${concatStringsSep "," flags}
          ''}
        '');

        ubiImage = (volumes:
        let
          ubinizeConfig = pkgs.writeText "ubinize.conf" (concatStringsSep "\n" volumes);
          inherit (pkgs.pkgsBuildBuild) mtdutils;
        in
        runCommand "ubinize" {
          depsBuildBuild = [ mtdutils ];
          # block size := 128kb
          # page size := 2048
          # ubninize opts := -E 5
        } ''
          ubinize -Q "$SOURCE_DATE_EPOCH" -o $out \
            -p ${config.hardware.ubi.physicalEraseBlockSize} -m ${config.hardware.ubi.minIOSize} \
            -e ${config.hardware.ubi.logicalEraseBlockSize} \
            ${ubinizeConfig}
        '');

        ubiDisk = ({ initramfs }:
        let
          initramfsUbi = ubiVolume {
            name = "rootfs";
            volumeId = 0;
            image = initramfs;
            flags = [ "autoresize" ];
          };
        in
          ubiImage [
            initramfsUbi
          ]);

        disk = ubiDisk {
          initramfs = config.system.outputs.rootubifs; # liminix.builders.squashfs config.filesystem.contents; #           # assert this is a proper FIT.
        };

      in
        disk;
  };
}
