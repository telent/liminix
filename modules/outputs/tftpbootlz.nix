{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  inherit (pkgs.lib.trivial) toHexString;
  o = config.system.outputs;
  cmdline = concatStringsSep " " config.boot.commandLine;
  cfg = config.boot.tftp;
  boot-scr =
    pkgs.buildPackages.runCommand "boot-scr" { nativeBuildInputs = [ pkgs.pkgsBuildBuild.dtc ];  } ''
      uimageSize=$(($(stat -L -c %s ${o.zimage}) + 0x1000 &(~0xfff)))
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
      tftpboot 0x${lib.toHexString cfg.loadAddress} result/zImage; tftpboot 0x$(printf %x $rootfsStart) result/rootfs ; tftpboot 0x$dtbStart result/dtb
      setexpr bootaddr 0x$dtbStart + \$filesize
      # lzmadec 0x${lib.toHexString cfg.loadAddress}  \$bootaddr
      # bootz \$bootaddr - 0x$dtbStart
      bootz 0x${lib.toHexString cfg.loadAddress} - 0x$dtbStart
      EOF
    '';
in {
  imports = [ ../ramdisk.nix ];
  options.boot.tftp.freeSpaceBytes = mkOption {
    type = types.int;
    default = 0;
  };
  options.system.outputs = {
    tftpbootlz = mkOption {
      type = types.package;
      description = ''
        tftpbootlz
        **********

        This is a variant of the tftpboot output intended for the
        Turris Omnia. It builds a uimage containing an uncompressed
        kernel, then compresses the resulting image to be decompressed
        using the u-boot lzmadec command. This is a workaround for an
        awkwardly low CONFIG_SYS_BOOTM_LEN setting in the U-Boot build
        for the device, which means that the regular tftpboot output
        would only work for very small kernels.
      '';
    };
  };
  config = {
    boot.ramdisk.enable = true;

    system.outputs = {
      tftpbootlz =
        let
          o = config.system.outputs; in
          pkgs.runCommand "tftpboot" {
            depsBuildBuild = [ pkgs.pkgsBuildBuild.lzma ];
          } ''
          mkdir $out
          cd $out
          ln -s ${o.rootfs} rootfs
          ln -s ${o.zimage} zImage
          ln -s ${o.manifest} manifest
          ln -s ${o.kernel.headers} build
          # lzma -c -z -9  < {uimage} > uimage.lz
          ln -s ${boot-scr}/dtb dtb
          ln -s ${boot-scr}/script boot.scr
       '';
    };
  };
}
