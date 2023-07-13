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
  imports = [ ./ramdisk.nix ];
  options.boot.tftp.freeSpaceBytes = mkOption {
    type = types.int;
    default = 0;
  };
  options.system.outputs = {
    tftpboot = mkOption {
      type = types.package;
      description = ''
        Directory containing files needed for TFTP booting
      '';
    };
    boot-scr = mkOption {
      type = types.package;
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
          ln -s ${o.boot-scr} boot.scr
       '';

      boot-scr =
        let
          inherit (pkgs.lib.trivial) toHexString;
          o = config.system.outputs;
        in
          pkgs.buildPackages.runCommand "boot-scr" {} ''
            uimageSize=$(($(stat -L -c %s ${o.uimage}) + 0x1000 &(~0xfff)))
            rootfsStart=0x$(printf %x $((${cfg.loadAddress} + 0x100000 + $uimageSize)))
            rootfsBytes=$(($(stat -L -c %s ${o.rootfs}) + 0x100000 &(~0xfffff)))
            rootfsBytes=$(($rootfsBytes + ${toString cfg.freeSpaceBytes} ))
            cmd="mtdparts=phram0:''${rootfsMb}M(rootfs) phram.phram=phram0,''${rootfsStart},''${rootfsBytes},${config.hardware.flash.eraseBlockSize} memmap=''${rootfsBytes}\$''${rootfsStart} root=/dev/mtdblock0";

            cat > $out << EOF
            setenv serverip ${cfg.serverip}
            setenv ipaddr ${cfg.ipaddr}
            setenv bootargs 'liminix $cmd'
            tftp 0x$(printf %x ${cfg.loadAddress}) result/uimage ; tftp 0x$(printf %x $rootfsStart) result/rootfs
            bootm 0x$(printf %x ${cfg.loadAddress})
            EOF
          '';
    };
  };
}
