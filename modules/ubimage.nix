{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types concatStringsSep;
  loadaddr = config.boot.tftp.loadAddress;
  cfg = config.boot.tftp;
  instructions = pkgs.writeText "INSTALL.md" ''

# First-time installation

First-time installation of a UBIFS Liminix system presently can only
be done from the U-Boot command line (or from a ramdisk-based recovery
system: see "kexecboot" but we don't have detailed instructions for
this process yet).

These steps were tested on a Belkin RT3200 (also known as Linksys
E8450).  Other devices may be set up differently, so use them as
inspiration and don't just paste them blindly. Consult the Liminix
manual for how to connect a serial cable to your device and get into
U-Boot

1) determine which MTD device is being used for UBI and the partition name:

    uboot>  ubi part
    Device 0: ubi0, MTD partition ubi

In this case the important value is `ubi0`

2) list the available volumes and create a new one on which to install Liminix

    uboot> ubi info l
    [ copious output scrolls past ]

Expect there to be existing volumes and for some or all of them to be
important. Unless you know what you're doing, don't remove anything
whose name suggests it's related to uboot, or any kind of backup or
recovery partition. To see how much space is free:

    uboot> ubi info
    [ ... ]
    UBI: available PEBs:             823

Now we can make our new root volume

    uboot> ubi create liminix -

3) transfer the root filesystem from the build system and write it
to the new volume

    uboot> setenv serverip ${cfg.serverip}
    uboot> setenv ipaddr ${cfg.ipaddr}
    uboot> tftpboot ${loadaddr} result/rootfs
    uboot> ubi write ${loadaddr} liminix $filesize

Now we have the root filesystem installed on the device. You
can even mount it and poke around using `ubifsmount ubi0:liminix;
ubifsls  /`

4) optional: before you configure the device to boot into Liminix
automatically, you can try booting it by hand to see if it works:

    uboot> ubifsmount ubi0:liminix
    uboot> ubifsload ${loadaddr} boot/uimage
    uboot> bootm ${loadaddr}

Once you've done this and you're happy with it, reset the device to
U-Boot. You don't need to recreate the volume but you do need to
repeat step 3.

5) Instructions for configuring autoboot are likely to be very
device-dependent. On the Linksys E8450/Belkin RT3200, the environment
variable `boot_production` governs what happens on a normal boot, so
you could do

    uboot> setenv boot_production 'led $bootled_pwr on ; ubifsmount ubi0:liminix; ubifsload ${loadaddr} boot/uimage; bootm  ${loadaddr}'

On other devices, some detective work may be needed. Try running
`printenv` and look for likely commands, try looking at the existing
boot process, maybe even try looking for documentation for that device.

6) Now you can reboot the device into Liminix

    uboot> reset

'';
in {
  options.system.outputs = {
    ubimage = mkOption {
      type = types.package;
      description = ''
        UBIFS image and instructions to install it
      '';
    };
  };

  config = mkIf (config.rootfsType == "ubifs") {
    system.outputs = {
      ubimage =
        let o = config.system.outputs; in
        pkgs.runCommand "ubimage" {} ''
          mkdir $out
          cd $out
          ln -s ${o.rootfs} rootfs
          ln -s ${instructions} INSTALL
       '';
    };
  };
}
