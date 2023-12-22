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
  tftpbootlz =
    pkgs.buildPackages.runCommand "tftpbootlz" {
      nativeBuildInputs = with pkgs.pkgsBuildBuild; [ lzma dtc ];
    } ''
      binsize() { local s=$(stat -L -c %s $1); echo $(($s + 0x1000 &(~0xfff))); }
      binsize64k() { local s=$(stat -L -c %s $1); echo $(($s + 0x10000 &(~0xffff))); }
      hex() { printf "0x%x" $1; }

      kernelStart=${toString cfg.loadAddress}
      kernelSize=$(binsize ${o.zimage})
      mkdir -p $out
      cat ${o.dtb} > $out/dtb
      fdtput -p -t lx $out/dtb /reserved-memory '#address-cells' 1
      fdtput -t lx $out/dtb /reserved-memory '#size-cells' 1
      fdtput $out/dtb /reserved-memory ranges
      fdtput -p -t s $out/dtb /reserved-memory/phram-rootfs compatible phram
      # can't calculate the actual address here until we know how
      # big the dtb will be
      fdtput -t lx $out/dtb /reserved-memory/phram-rootfs reg 0xdead 0xcafe
      cmd="liminix ${cmdline} mtdparts=phram0:999999999999(rootfs) phram.phram=phram0,999999999999,999999999999,${toString config.hardware.flash.eraseBlockSize} root=/dev/mtdblock0";
      fdtput -t s $out/dtb /chosen bootargs "$cmd"

      dtbStart=$(($kernelStart + $kernelSize))
      dtbSize=$(binsize $out/dtb)
      rootfsOrigSize=$(binsize64k ${o.rootfs})
      lzma -z9cv ${o.rootfs} > $out/rootfs.lz

      rootfsLzSize=$(binsize $out/rootfs.lz)
      rootfsLzStart=$(($dtbStart + $dtbSize))
      rootfsOrigStart=$(($rootfsLzStart + $rootfsLzSize))
      fdtput -t lx $out/dtb /reserved-memory/phram-rootfs reg $(printf "%x" $rootfsOrigStart) $(printf "%x"  $rootfsOrigSize)

      cmd="liminix ${cmdline} mtdparts=phram0:''${rootfsOrigSize}(rootfs) phram.phram=phram0,''${rootfsOrigStart},''${rootfsOrigSize},${toString config.hardware.flash.eraseBlockSize} root=/dev/mtdblock0";
      fdtput -t s $out/dtb /chosen bootargs "$cmd"

      # dtc -I dtb  -O dts  -o /dev/stdout $out/dtb | grep -A10 reserved-memory; exit 1

      (cd $out;
      ln -s ${o.zimage} zImage
      ln -s ${o.manifest} manifest
      ln -s ${o.kernel.headers} build)

      cat > $out/boot.scr << EOF
      setenv serverip ${cfg.serverip}
      setenv ipaddr ${cfg.ipaddr}
      tftpboot $(hex $kernelStart) result/zImage; tftpboot $(hex $dtbStart) result/dtb ; tftpboot $(hex $rootfsLzStart) result/rootfs.lz
      lzmadec $(hex $rootfsLzStart) $(hex $rootfsOrigStart)
      bootz $(hex $kernelStart) - $(hex $dtbStart)
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
        Turris Omnia. It uses a zImage instead of a uimage, as a
        workaround for an awkwardly low CONFIG_SYS_BOOTM_LEN setting
        in the U-Boot build for the device which means it won't boot
        uimages unless they're teeny tiny.

        As a bonus, it also uses lzma compression on the rootfs,
        which reduces a 20MB ext4 image to around 4MB
      '';
    };
  };
  config = {
    boot.ramdisk.enable = true;
    system.outputs = {
      inherit tftpbootlz;
    };
  };
}
