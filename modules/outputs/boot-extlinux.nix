{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    concatStringsSep
    ;
  inherit (pkgs.pseudofile) dir symlink;
  cfg = config.boot.loader.extlinux;
  o = config.system.outputs;
  cmdline = concatStringsSep " " config.boot.commandLine;
  wantsDtb = config.hardware.dts ? src && config.hardware.dts.src != null;
in
{
  options.boot.loader.extlinux.enable = mkEnableOption "extlinux";

  config = mkIf cfg.enable {
    system.outputs.bootfiles = pkgs.runCommand "extlinux" { } ''
      mkdir $out
      cd $out
      ${if wantsDtb then "cp ${o.dtb} dtb" else "true"}
      cp ${o.initramfs} initramfs
      cp ${o.kernel.zImage} kernel
      mkdir extlinux
      cat > extlinux/extlinux.conf << _EOF
      menu title Liminix
      timeout 40
      label Liminix
        kernel /boot/kernel
        # initrd /boot/initramfs
        append ${cmdline} 
        ${if wantsDtb then "fdt /boot/dtb" else ""}
      _EOF
    '';
    filesystem = dir {
      boot = symlink config.system.outputs.bootfiles;
    };
  };
}
