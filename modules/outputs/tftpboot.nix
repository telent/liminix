{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  cfg = config.boot.tftp;
in {
  imports = [ ../ramdisk.nix ];
  options.boot.tftp.freeSpaceBytes = mkOption {
    type = types.int;
    default = 0;
  };
  options.system.outputs = {
    tftpboot = mkOption {
      type = types.package;
      description = ''
        tftpboot
        ********

        This output is intended for developing on a new device.
        It assumes you have a serial connection and a
        network connection to the device and that your
        build machine is running a TFTP server.

        The output is a directory containing kernel and
        root filesystem image, and a script :file:`boot.scr` of U-Boot
        commands that will load the images into memory and
        run them directly,
        instead of first writing them to flash. This saves
        time and erase cycles.

        It uses the Linux `phram <https://github.com/torvalds/linux/blob/master/drivers/mtd/devices/phram.c>`_ driver to emulate a flash device using a segment of physical RAM.
      '';
    };
    boot-scr = mkOption {
      type = types.package;
      internal = true;
      description = ''
        U-Boot commands to load and boot a kernel and rootfs over TFTP.
        Copy-paste into the device boot monitor
      '';
    };
  };
  config = {
    boot.ramdisk.enable = true;

    system.outputs = rec {
      tftpboot =
        let o = config.system.outputs; in
        pkgs.runCommand "tftpboot" {} ''
          mkdir $out
          cd $out
          ln -s ${o.rootfs} rootfs
          ln -s ${o.kernel} vmlinux
          ln -s ${o.manifest} manifest
          ln -s ${o.kernel.headers} build
          ln -s ${o.uimage} uimage
          ln -s ${o.boot-scr}/dtb dtb
          ln -s ${o.boot-scr}/script boot.scr
       '';

      boot-scr =
        let
          inherit (pkgs.lib.trivial) toHexString;
          o = config.system.outputs;
          cmdline = concatStringsSep " " config.boot.commandLine;
        in
          pkgs.buildPackages.runCommand "boot-scr" { nativeBuildInputs = [ pkgs.pkgsBuildBuild.dtc ];  } ''
            uimageSize=$(($(stat -L -c %s ${o.uimage}) + 0x1000 &(~0xfff)))
            rootfsStart=0x$(printf %x $((${toString cfg.loadAddress} + 0x100000 + $uimageSize   &(~0xfffff) )))
            rootfsBytes=$(($(stat -L -c %s ${o.rootfs}) + 0x100000 &(~0xfffff)))
            rootfsBytes=$(($rootfsBytes + ${toString cfg.freeSpaceBytes} ))
            rootfsMb=$(($rootfsBytes >> 20))
            cmd="mtdparts=phram0:''${rootfsMb}M(rootfs) phram.phram=phram0,''${rootfsStart},''${rootfsBytes},${toString config.hardware.flash.eraseBlockSize} root=/dev/mtdblock0";

            dtbStart=$(printf %x $((${toString cfg.loadAddress} + $rootfsBytes + 0x100000 + $uimageSize )))

            mkdir $out
            cat ${o.dtb} > $out/dtb
            fdtput -p -t s $out/dtb /reserved-memory/phram-rootfs compatible phram
            fdtput -p -t lx $out/dtb /reserved-memory/phram-rootfs reg 0 $rootfsStart 0 $(printf %x $rootfsBytes)

            dtbBytes=$(($(stat -L -c %s $out/dtb) + 0x1000 &(~0xfff)))

            cat > $out/script << EOF
            setenv serverip ${cfg.serverip}
            setenv ipaddr ${cfg.ipaddr}
            setenv bootargs 'liminix ${cmdline} $cmd'
            tftpboot 0x${lib.toHexString cfg.loadAddress} result/uimage ; tftpboot 0x$(printf %x $rootfsStart) result/rootfs ; tftpboot 0x$dtbStart result/dtb
            bootm 0x${lib.toHexString cfg.loadAddress} - 0x$dtbStart
            EOF
          '';
    };
  };
}
