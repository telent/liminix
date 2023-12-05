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
      # cp {o.dtb} dtb
      cp ${o.initramfs} initramfs
      gzip -9f < ${o.kernel} > kernel.gz
      mkdir extlinux
      cat > extlinux/extlinux.conf << _EOF
      menu title Liminix
      timeout 100
      label Liminix
        kernel /boot/kernel.gz
        initrd /boot/initramfs
        append ${cmdline}
        # fdt /boot/dtb
      _EOF
    '';
  };
}
