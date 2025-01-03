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
      internal = true;          # component of mtdimage
      description = ''
        Binary image (combining kernel, FDT, rootfs, initramfs
        if needed, etc) for the target device.
      '';
    };
    flash-scr = mkOption {
      type = types.package;
      internal = true;          # component of mtdimage
      description = ''
        Copy-pastable U-Boot commands to TFTP download the
        image and write it to flash
      '';
    };
    mtdimage = mkOption {
      type = types.package;
      description = ''
        mtdimage
        **********

        This creates an image called :file:`firmware.bin` suitable for
        squashfs or jffs2 systems. It can be flashed from U-Boot (if
        you have a serial console connection), or on some devices from
        the vendor firmware, or from a Liminix kexecboot system.

        If you are flashing from U-Boot, the file
        :file:`flash.scr` is a sequence of commands
        which you can paste at the U-Boot prompt to
        to transfer the firmware file from a TFTP server and
        write it to flash. **Please read the script before
        running it: flash operations carry the potential to
        brick your device**

        .. NOTE::

           TTL serial connections typically have no form of flow
           control and so don't always like having massive chunks of
           text pasted into them - and U-Boot may drop characters
           while it's busy. So don't necessarily expect to copy-paste
           the whole of :file:`flash.scr` into a terminal emulator and
           have it work just like that. You may need to paste each
           line one at a time, or even retype it.
      '';
    };
  };

  config = {
    kernel = {
      config = {
        # this needs to be conditional on "not qemu"
        MTD_SPLIT_UIMAGE_FW = "y";
      } // lib.optionalAttrs (pkgs.stdenv.isMips) {
        # https://stackoverflow.com/questions/26466470/can-the-logical-erase-block-size-of-an-mtd-device-be-increased
        MTD_SPI_NOR_USE_4K_SECTORS = "n";
      };
    };

    programs.busybox.applets = [
      "flashcp"
    ];

    system.outputs = {
      firmware =
        let
          o = config.system.outputs;
          bs = toString config.hardware.flash.eraseBlockSize;
        in pkgs.runCommand "firmware" {} ''
          dd if=${o.uimage} of=$out bs=${bs} conv=sync
          dd if=${o.rootfs} of=$out bs=${bs} conv=sync,nocreat,notrunc oflag=append
        '';
      mtdimage =
        let o = config.system.outputs; in
        # could use trivial-builders.linkFarmFromDrvs here?
        pkgs.runCommand "mtdimage" {} ''
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
            tftp 0x${toHexString tftp.loadAddress} result/firmware.bin
            erase 0x${toHexString flash.address} +0x${toHexString flash.size}
            cp.b 0x${toHexString tftp.loadAddress} 0x${toHexString flash.address} \''${filesize}
            echo command line was ${builtins.toJSON (concatStringsSep " " config.boot.commandLine)}
            EOF
          '';
    };
  };
}
