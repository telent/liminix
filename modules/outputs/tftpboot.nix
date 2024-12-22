{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  cfg = config.boot.tftp;
  hw = config.hardware;
  arch = pkgs.stdenv.hostPlatform.linuxArch;
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
    compressRoot = mkOption {
      type = types.bool;
      default = false;
    };
    appendDTB = mkOption {
      type = types.bool;
      default = false;
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
          o = config.system.outputs;
          image = let choices = {
            uimage = o.uimage;
            zimage = o.kernel.zImage;
          }; in choices.${cfg.kernelFormat};
          bootCommand = let choices = {
            uimage = "bootm";
            zimage = "bootz";
          }; in choices.${cfg.kernelFormat};

          cmdline = concatStringsSep " " config.boot.commandLine;
          objcopy = "${pkgs.stdenv.cc.bintools.targetPrefix}objcopy";
          stripAndZip = ''
            ${objcopy} -O binary -R .reginfo -R .notes -R .note -R .comment -R .mdebug -R .note.gnu.build-id -S vmlinux.elf vmlinux.bin
            rm -f vmlinux.bin.lzma ; lzma -k -z  vmlinux.bin
          '';
        in
          pkgs.runCommand "tftpboot" { nativeBuildInputs = with pkgs.pkgsBuildBuild; [ lzma dtc pkgs.stdenv.cc ubootTools ];  } ''
            mkdir $out
            cd $out
            binsize() { local s=$(stat -L -c %s $1); echo $(($s + 0x1000 &(~0xfff))); }
            binsize64k() { local s=$(stat -L -c %s $1); echo $(($s + 0x10000 &(~0xffff))); }
            hex() { printf "0x%x" $1; }

            rootfsStart=${toString cfg.loadAddress}
            rootfsSize=$(binsize64k ${o.rootfs} )
            rootfsSize=$(($rootfsSize + ${toString cfg.freeSpaceBytes} ))

            ln -s ${o.manifest} manifest
            ln -s ${o.kernel} vmlinux  # handy for gdb

            # if we are transferring kernel and dtb separately, the
            # dtb has to precede the kernel in ram, because zimage
            # decompression code will assume that any memory after the
            # end of the kernel is free

            dtbStart=$(($rootfsStart + $rootfsSize))
            ${if cfg.compressRoot
              then ''
                lzma -z9cv ${o.rootfs} > rootfs.lz
                rootfsLzStart=$dtbStart
                rootfsLzSize=$(binsize rootfs.lz)
                dtbStart=$(($dtbStart + $rootfsLzSize))
              ''
              else ''
                ln -s ${o.rootfs} rootfs
              ''
             }

            cat ${o.dtb} > dtb
            address_cells=$(fdtget dtb / '#address-cells')
            size_cells=$(fdtget dtb / '#size-cells')
            if [ $address_cells -gt 1 ]; then ac_prefix=0; fi
            if [ $size_cells -gt 1 ]; then sz_prefix=0; fi

            fdtput -p dtb /reserved-memory '#address-cells' $address_cells
            fdtput -p dtb /reserved-memory '#size-cells' $size_cells
            fdtput -p dtb /reserved-memory ranges
            node=$(printf "phram-rootfs@%x" $rootfsStart)
            fdtput -p -t s dtb /reserved-memory/$node compatible phram
            fdtput -p -t lx dtb /reserved-memory/$node reg $ac_prefix $(hex $rootfsStart) $sz_prefix $(hex $rootfsSize)

            cmd="liminix ${cmdline} mtdparts=phram0:''${rootfsSize}(rootfs) phram.phram=phram0,''${rootfsStart},''${rootfsSize},${toString config.hardware.flash.eraseBlockSize} root=/dev/mtdblock0";
            fdtput -t s dtb /chosen ${config.boot.commandLineDtbNode} "$cmd"

            dtbSize=$(binsize ./dtb )

            ${if cfg.appendDTB then ''
              imageStart=$dtbStart
              # re-package image with updated dtb
              cat ${o.kernel} > vmlinux.elf
              ${objcopy} --update-section .appended_dtb=dtb vmlinux.elf
              ${stripAndZip}
              mkimage -A ${arch} -O linux -T kernel -C lzma -a $(hex ${toString hw.loadAddress}) -e $(hex ${toString hw.entryPoint}) -n '${lib.toUpper arch} Liminix Linux tftpboot' -d vmlinux.bin.lzma image
              # dtc -I dtb -O dts -o /dev/stdout dtb | grep -A10 chosen ; exit 1
              tftpcmd="tftpboot $(hex $imageStart) result/image "
              bootcmd="bootm $(hex $imageStart)"
            '' else ''
              imageStart=$(($dtbStart + $dtbSize))
              tftpcmd="tftpboot $(hex $imageStart) result/image; tftpboot $(hex $dtbStart) result/dtb "
              ln -s ${image} image
              bootcmd="${bootCommand} $(hex $imageStart) - $(hex $dtbStart)"
            ''}

            cat > boot.scr << EOF
            setenv serverip ${cfg.serverip}
            setenv ipaddr ${cfg.ipaddr}
            ${
              if cfg.compressRoot
              then "tftpboot $(hex $rootfsLzStart) result/rootfs.lz"
              else "tftpboot $(hex $rootfsStart) result/rootfs"
            }; $tftpcmd
            ${if cfg.compressRoot
              then "lzmadec $(hex $rootfsLzStart)  $(hex $rootfsStart); "
              else ""
             } $bootcmd
            EOF
         '';

    };
  };
}
