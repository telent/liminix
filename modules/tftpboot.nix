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
  config = {
    boot.ramdisk.enable = true;

    outputs.tftpboot =
      let o = config.outputs; in
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

    outputs.boot-scr =
      let
        inherit (pkgs.lib.trivial) toHexString;
      in
        pkgs.buildPackages.runCommand "boot-scr" {} ''
          uimageSize=$(($(stat -L -c %s ${config.outputs.uimage}) + 0x1000 &(~0xfff)))
          rootfsStart=0x$(printf %x $((${cfg.loadAddress} + 0x100000 + $uimageSize)))
          rootfsBytes=$(($(stat -L -c %s ${config.outputs.rootfs}) + 0x100000 &(~0xfffff)))
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
}
