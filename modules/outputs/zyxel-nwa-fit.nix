{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types concatStringsSep;
  models = "6b e1 6f e1 ff ff ff ff ff ff";
in {
  options.system.outputs = {
    zyxel-nwa-fit = mkOption {
      type = types.package;
      description = ''
zyxel-nwa-fit
*************

This output provides a FIT image for Zyxel NWA series
containing a kernel image and an UBIFS rootfs.

It can usually be used as a factory image to install Liminix
on a system with pre-existing firmware and OS.
      '';
    };
  };

  imports = [
    ./ubivolume.nix
  ];

  config = mkIf (config.rootfsType == "ubifs") {

    system.outputs.zyxel-nwa-fit =
      let 
        o = config.system.outputs;
        # 8129kb padding.
        paddedKernel = pkgs.runCommand "padded-kernel" {} ''
          cp --no-preserve=mode ${o.uimage} $out
          dd if=/dev/zero of=$out bs=1 count=1 seek=8388607
        '';
        firmwareImage = pkgs.runCommand "firmware-image" {} ''
          cat ${paddedKernel} ${o.rootfs} > $out
        '';
        dts = pkgs.writeText "image.its" ''
        /dts-v1/;

        / {
          description = "Zyxel FIT (Flattened Image Tree)";
          compat-models = [${models}];
          #address-cells = <1>;

          images {
            firmware {
              data = /incbin/("${firmwareImage}");
              type = "firmware";
              compression = "none";
              hash@1 {
                algo = "sha1";
              };
            };
          };
        };
      '';
      in
      pkgs.runCommand "zyxel-nwa-fit" {
        nativeBuildInputs = [ pkgs.pkgsBuildBuild.ubootTools pkgs.pkgsBuildBuild.dtc ];
      } ''
        mkimage -f ${dts} $out
      '';
  };
}
