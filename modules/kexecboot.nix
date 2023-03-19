{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption mkForce types concatStringsSep;
in {
  imports = [ ./ramdisk.nix ];
  config = {
    boot.ramdisk.enable = true;

    kernel.config.MIPS_CMDLINE_FROM_DTB = "y";
    kernel.config.MIPS_CMDLINE_FROM_BOOTLOADER = mkForce "n";

    outputs.kexecboot =
      let o = config.outputs; in
      pkgs.runCommand "kexecboot" {} ''
        mkdir $out
        cd $out
        ln -s ${o.squashfs} squashfs
        ln -s ${o.kernel} kernel
        ln -s ${o.manifest} manifest
        ln -s ${o.boot-sh} boot.sh
        ln -s ${pkgs.kexec-tools}/bin/kexec ./kexec
        ln -s ${o.dtb} dtb
     '';

    outputs.boot-sh =
      let
        inherit (pkgs) kexec-tools;
        inherit (pkgs.lib.trivial) toHexString;
        inherit (config.outputs) squashfs kernel;
        cmdline = concatStringsSep " " config.boot.commandLine;
      in
        pkgs.buildPackages.runCommand "boot.sh.sh" {
        } ''
          squashfsStart=${toString (100 * 1024 * 1024)}
          squashfsBytes=$(stat -L -c %s ${squashfs})
          append_cmd="mtdparts=phram0:''${squashfsBytes}(rootfs) phram.phram=phram0,''${squashfsStart},''${squashfsBytes} memmap=''${squashfsBytes}\$''${squashfsStart}";
          cat > $out <<EOF
          #!/bin/sh
          test -d \$1
          cd \$1
          ./kexec -f -d --map-file squashfs@$squashfsStart --dtb dtb --command-line '${cmdline} $append_cmd' kernel
          EOF
        '';
  };
}
