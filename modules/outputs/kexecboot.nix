{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
in {
  imports = [ ../ramdisk.nix ];
  options.system.outputs = {
    kexecboot = mkOption {
      type = types.package;
      description = ''
        kexecboot
        *********

        Directory containing files needed for kexec booting.
        Can be copied onto the target device using ssh or similar
      '';
    };
    boot-sh = mkOption {
      type = types.package;
      description = ''
        Shell script to run on the target device that invokes
        kexec with appropriate options
      '';
    };
  };
  config = {
    boot.ramdisk.enable = true;
    system.outputs = {
      kexecboot =
        let o = config.system.outputs; in
        pkgs.runCommand "kexecboot" {} ''
          mkdir $out
          cd $out
          ln -s ${o.rootfs} rootfs
          ln -s ${o.kernel} kernel
          ln -s ${o.manifest} manifest
          ln -s ${o.boot-sh} boot.sh
          ln -s ${pkgs.kexec-tools-static}/bin/kexec ./kexec
          ln -s ${o.dtb} dtb
       '';

      boot-sh =
        let
          inherit (config.system.outputs) rootfs;
          cmdline = concatStringsSep " " config.boot.commandLine;
        in
          pkgs.buildPackages.runCommand "boot.sh.sh" {
          } ''
            rootfsStart=${toString (100 * 1024 * 1024)}
            rootfsBytes=$(stat -L -c %s ${rootfs})
            append_cmd="mtdparts=phram0:''${rootfsBytes}(rootfs) phram.phram=phram0,''${rootfsStart},''${rootfsBytes} memmap=''${rootfsBytes}\$''${rootfsStart}";
            cat > $out <<EOF
            #!/bin/sh
            test -d \$1
            cd \$1
            ./kexec -f -d --map-file rootfs@$rootfsStart --dtb dtb --command-line '${cmdline} $append_cmd' kernel
            EOF
          '';
    };
  };
}
