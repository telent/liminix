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
  options.system.outputs = {
    firmware = mkOption {
      type = types.package;
      internal = true;          # component of flashimage
      description = ''
        Binary image (combining kernel, FDT, rootfs, initramfs
        if needed, etc) for the target device.
      '';
    };
    flash-scr = mkOption {
      type = types.package;
      internal = true;          # component of flashimage
      description = ''
        Copy-pastable U-Boot commands to TFTP download the
        image and write it to flash
      '';
    };
    flashimage = mkOption {
      type = types.package;
      description = ''
        Flashable image for the target device, and the script to
        install it
      '';
    };
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

    system.outputs = {
      firmware =
        let o = config.system.outputs; in
        pkgs.runCommand "firmware" {} ''
          dd if=${o.uimage} of=$out bs=128k conv=sync
          dd if=${o.rootfs} of=$out bs=128k conv=sync,nocreat,notrunc oflag=append
        '';
      flashimage =
        let o = config.system.outputs; in
        # could use trivial-builders.linkFarmFromDrvs here?
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

      flash-scr =
        let
          inherit (pkgs.lib.trivial) toHexString;
          inherit (config.hardware) flash;
        in
          pkgs.buildPackages.runCommand "" {} ''
            imageSize=$(stat -L -c %s ${config.system.outputs.firmware})
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
  };
}
