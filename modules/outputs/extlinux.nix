{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types concatStringsSep;
  cfg = config.boot.loader.extlinux;
  o = config.system.outputs;
  cmdline = concatStringsSep " " config.boot.commandLine;
in {
  options.system.outputs.extlinux = mkOption {
    type = types.package;
    # description = "";
  };
  options.boot.loader.extlinux.enable = mkEnableOption "extlinux";

  config =  { # mkIf cfg.enable {
    system.outputs.extlinux = pkgs.runCommand "extlinux" {} ''
      mkdir $out
      cd $out
      ln -s ${o.dtb} dtb
      ln -s ${o.initramfs} initramfs
      gzip -9f < ${o.kernel} > kernel.gz
      cat > extlinux.conf << _EOF
      menu title Liminix
      timeout 100
      label Liminix
        kernel kernel.gz
        initrd initramfs
        fdt dtb
        append ${cmdline}
      _EOF
    '';
  };
}
