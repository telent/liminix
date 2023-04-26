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
  };
  config = {
    kernel = {
      config = {
        MTD_SPLIT_UIMAGE_FW = "y";
      };
    };

    programs.busybox.applets = [
      "flashcp"
    ];

    outputs.firmware =
      let o = config.outputs; in
      pkgs.runCommand "firmware" {} ''
        dd if=${o.uimage} of=$out bs=128k conv=sync
        dd if=${o.rootfs} of=$out bs=128k conv=sync,nocreat,notrunc oflag=append
      '';
    outputs.flashimage =
      let o = config.outputs; in
      pkgs.runCommand "flashimage" {} ''
        mkdir $out
        cd $out
        ln -s ${o.firmware} firmware.bin
        ln -s ${o.rootfs} rootfs
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
        inherit (config.hardware) flash;
      in
        pkgs.buildPackages.runCommand "" {} ''
          imageSize=$(stat -L -c %s ${config.outputs.firmware})
          cat > $out << EOF
          setenv serverip ${tftp.serverip}
          setenv ipaddr ${tftp.ipaddr}
          tftp 0x$(printf %x ${tftp.loadAddress}) result/firmware.bin
          erase 0x$(printf %x ${flash.address}) +${flash.size}
          cp.b 0x$(printf %x ${tftp.loadAddress}) 0x$(printf %x ${flash.address}) \''${filesize}
          echo command line was ${builtins.toJSON (concatStringsSep " " config.boot.commandLine)}
          EOF
        '';

  };
}
