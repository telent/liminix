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
  options.boot.tftp = {
    freeSpaceBytes = mkOption {
      type = types.int;
      default = 0;
    };
    kernelFormat = mkOption {
      type = types.enum [ "zimage" "uimage" ];
      default = "uimage";
    };
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
  };
  config = {
    boot.ramdisk.enable = true;

    system.outputs = rec {
      tftpboot =
        let
          inherit (pkgs.lib.trivial) toHexString;
          o = config.system.outputs;
          image = let choices = {
            uimage = o.uimage;
            zimage = o.zimage;
          }; in choices.${cfg.kernelFormat};
          bootCommand = let choices = {
            uimage = "bootm";
            zimage = "bootz";
          }; in choices.${cfg.kernelFormat};
          cmdline = concatStringsSep " " config.boot.commandLine;
        in
          pkgs.runCommand "tftpboot" { nativeBuildInputs = [ pkgs.pkgsBuildBuild.dtc ];  } ''
            mkdir $out
            cd $out
            ln -s ${o.rootfs} rootfs
            ln -s ${o.kernel} vmlinux
            ln -s ${o.manifest} manifest
            ln -s ${o.kernel.headers} build
            ln -s ${image} image
            uimageSize=$(($(stat -L -c %s ${image}) + 0x1000 &(~0xfff)))
            rootfsStart=$(printf %x $((${toString cfg.loadAddress} + 0x100000 + $uimageSize   &(~0xfffff) )))
            rootfsBytes=$(($(stat -L -c %s ${o.rootfs}) + 0x100000 &(~0xfffff)))
            rootfsBytes=$(($rootfsBytes + ${toString cfg.freeSpaceBytes} ))
            rootfsMb=$(($rootfsBytes >> 20))
            cmd="mtdparts=phram0:''${rootfsMb}M(rootfs) phram.phram=phram0,0x''${rootfsStart},''${rootfsBytes},${toString config.hardware.flash.eraseBlockSize} root=/dev/mtdblock0";

            dtbStart=$(printf %x $((${toString cfg.loadAddress} + $rootfsBytes + 0x100000 + $uimageSize )))

            cat ${o.dtb} > $out/dtb
            address_cells=$(fdtget $out/dtb / '#address-cells')
            size_cells=$(fdtget $out/dtb / '#size-cells')
            if [ $address_cells -gt 1 ]; then ac_prefix=0; fi
            if [ $size_cells -gt 1 ]; then sz_prefix=0; fi

            fdtput -p  $out/dtb /reserved-memory '#address-cells' $address_cells
            fdtput -p  $out/dtb /reserved-memory '#size-cells' $size_cells
            fdtput -p  $out/dtb /reserved-memory ranges
            fdtput -p -t s $out/dtb /reserved-memory/phram-rootfs@$rootfsStart compatible phram
            fdtput -p -t lx $out/dtb /reserved-memory/phram-rootfs@$rootfsStart reg $ac_prefix 0x$rootfsStart $sz_prefix $(printf %x $rootfsBytes)

            # dtc -I dtb -O dts -o /dev/stdout $out/dtb | grep -A10 reserved-mem ; exit 1
            dtbBytes=$(($(stat -L -c %s $out/dtb) + 0x1000 &(~0xfff)))

            cat > $out/boot.scr << EOF
            setenv serverip ${cfg.serverip}
            setenv ipaddr ${cfg.ipaddr}
            setenv bootargs 'liminix ${cmdline} $cmd'
            tftpboot 0x${lib.toHexString cfg.loadAddress} result/image ; tftpboot 0x$rootfsStart result/rootfs ; tftpboot 0x$dtbStart result/dtb
            ${bootCommand} 0x${lib.toHexString cfg.loadAddress} - 0x$dtbStart
            EOF
         '';

    };
  };
}
