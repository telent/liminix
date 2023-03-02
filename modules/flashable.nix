{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  inherit (config.boot) tftp;
in {
  options = {
    device.flash = {
      address = mkOption { type = types.str; };
      size = mkOption { type = types.str; };
    };
  };
  config = {
    kernel = {
      config = {
        MTD_SPLIT_UIMAGE_FW = "y";
        # ignore the commandline provided by U-Boot because it's most
        # likely wrong
        MIPS_CMDLINE_FROM_BOOTLOADER = lib.mkForce "n";
        MIPS_CMDLINE_FROM_DTB = "y";
      };
    };

    boot.commandLine = [
      "root=${config.device.rootDevice}"
    ];
    outputs.firmware =
      let o = config.outputs; in
      pkgs.runCommand "firmware" {} ''
        dd if=${o.uimage} of=$out bs=128k conv=sync
        dd if=${o.squashfs} of=$out bs=128k conv=sync,nocreat,notrunc oflag=append
      '';
    outputs.flashable =
      let o = config.outputs; in
      pkgs.runCommand "flashable" {} ''
        mkdir $out
        cd $out
        ln -s ${o.firmware} firmware.bin
        ln -s ${o.squashfs} squashfs
        ln -s ${o.kernel} vmlinux
        ln -s ${o.manifest} manifest
        ln -s ${o.kernel.headers} build
        ln -s ${o.uimage} uimage
        ln -s ${o.dtb} dtb
        ln -s ${o.flash-scr} flash.scr
     '';

    outputs.flash-scr =
      let
        inherit (pkgs.lib.trivial) toHexString;
        inherit (pkgs.lib.lists) concatStringsSep;
        inherit (config.device) flash;
      in
        pkgs.buildPackages.runCommand "" {} ''
          imageSize=$(stat -L -c %s ${config.outputs.firmware})
          cat > $out << EOF
          setenv serverip ${tftp.serverip}
          setenv ipaddr ${tftp.ipaddr}
          tftp 0x$(printf %x ${tftp.loadAddress}) result/firmware.bin
          erase 0x$(printf %x ${flash.address}) +0x$(printf %x ${flash.size})
          cp.b 0x$(printf %x ${tftp.loadAddress}) 0x$(printf %x ${flash.address}) \''${filesize}
          echo command line was ${builtins.toJSON (concatStringsSep " " config.boot.commandLine)}
          EOF
        '';

  };
}
