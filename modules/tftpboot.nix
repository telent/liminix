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
  options = {
    boot = {
      tftp = {
        loadAddress = mkOption { type = types.str; };
        # These names match the uboot environment variables. I reserve
        # the right to change them if I think of better ones.
        ipaddr =  mkOption { type = types.str; };
        serverip =  mkOption { type = types.str; };
        enable =  mkOption { type = types.boolean; };
      };
    };
  };
  config = {
    kernel = {
      config = {
        MTD = "y";
        MTD_PHRAM = "y";
        MTD_CMDLINE_PARTS = "y";
        MIPS_CMDLINE_FROM_BOOTLOADER = "y";

        # one or more of the following is required to get from
        # VFS: Cannot open root device "1f00" or unknown-block(31,0): error -6
        # to
        # VFS: Mounted root (squashfs filesystem) readonly on device 31:0.
        MTD_OF_PARTS = "y";
        PARTITION_ADVANCED = "y";
        MSDOS_PARTITION = "y";
        EFI_PARTITION = "y";
        MTD_BLKDEVS = "y";
        MTD_BLOCK = "y";

        # CONFIG_MTD_MTDRAM=m         c'est quoi?
      };

    };
    outputs.tftproot =
      let o = config.outputs; in
      pkgs.runCommand "tftproot" {} ''
        mkdir $out
        cd $out
        ln -s ${o.squashfs} squashfs
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
        pkgs.buildPackages.runCommand "" {} ''
          uimageSize=$(($(stat -L -c %s ${config.outputs.uimage}) + 0x1000 &(~0xfff)))
          squashfsStart=0x$(printf %x $((${cfg.loadAddress} + 0x100000 + $uimageSize)))
          squashfsBytes=$(($(stat -L -c %s ${config.outputs.squashfs}) + 0x100000 &(~0xfffff)))
          squashfsMb=$(($squashfsBytes >> 20))
          cmd="mtdparts=phram0:''${squashfsMb}M(nix) phram.phram=phram0,''${squashfsStart},''${squashfsMb}Mi memmap=''${squashfsMb}M\$''${squashfsStart} root=1f00";
          cat > $out << EOF
          setenv serverip ${cfg.serverip}
          setenv ipaddr ${cfg.ipaddr}
          setenv bootargs '${concatStringsSep " " config.boot.commandLine} $cmd'
          tftp 0x$(printf %x ${cfg.loadAddress}) result/uimage ; tftp 0x$(printf %x $squashfsStart) result/squashfs
          bootm 0x$(printf %x ${cfg.loadAddress})
          EOF
        '';

  };
}
