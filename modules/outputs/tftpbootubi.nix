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
    tftpbootubi = mkOption {
      type = types.package;
      description = ''
        tftpbootubi
        ***********

        This output is intended for developing on a new device that
        uses a UBI layout / ubifs root filesystem, but which cannot
        load the kernel directly from inside the ubi image.
        It assumes you have a serial connection and a
        network connection to the device and that your
        build machine is running a TFTP server.

        The output is a directory containing kernel and
        a ubifs root filesystem image. The ubifs image will currently
        need to be manually written from a booted system (e.g. with
        OpenWRT), using ubimkvol, ubiupdatevol, etc. Once that is done
        the kernel can be booted over tftp; the script :file:`boot.scr`
        contains U-Boot commands that will load the kernel etc into memory and
        boot it directly.
      '';
    };
  };
  config = {
    boot.ramdisk.enable = true;

    system.outputs = rec {
      rootfs = config.system.outputs.rootubifs;
      tftpbootubi =
        let
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
          objcopy = "${pkgs.stdenv.cc.bintools.targetPrefix}objcopy";
          stripAndZip = ''
            ${objcopy} -O binary -R .reginfo -R .notes -R .note -R .comment -R .mdebug -R .note.gnu.build-id -S vmlinux.elf vmlinux.bin
            rm -f vmlinux.bin.lzma ; lzma -k -z  vmlinux.bin
          '';
        in
          pkgs.runCommand "tftpbootubi" { nativeBuildInputs = with pkgs.pkgsBuildBuild; [ lzma dtc pkgs.stdenv.cc ubootTools ];  } ''
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
            cmd="liminix ${cmdline}";

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

# vim: set ts=2 sw=2 sta et:
