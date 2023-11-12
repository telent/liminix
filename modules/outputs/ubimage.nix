{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types concatStringsSep;
  cfg = config.boot.tftp;
  instructions = pkgs.writeText "env.scr" ''
    setenv serverip ${cfg.serverip}
    setenv ipaddr ${cfg.ipaddr}
    setenv loadaddr ${cfg.loadAddress}
'';
in {
  options.system.outputs = {
    ubimage = mkOption {
      type = types.package;
      description = ''
ubimage
*******

This output provides a UBIFS filesystem image and a small U-Boot script
to make the manual installation process very slightly simpler. You will
need a serial connection and a network connection to a TFTP server
containing the filesystem image it creates.

.. warning:: These steps were tested on a Belkin RT3200 (also known as
             Linksys E8450).  Other devices may be set up differently,
             so use them as inspiration and don't just paste them
             blindly.

1) determine which MTD device is being used for UBI, and the partition name:

.. code-block:: console

    uboot>  ubi part
    Device 0: ubi0, MTD partition ubi

In this case the important value is ``ubi0``

2) list the available volumes and create a new one on which to install Liminix

.. code-block:: console

    uboot> ubi info l
    [ copious output scrolls past ]

Expect there to be existing volumes and for some or all of them to be
important. Unless you know what you're doing, don't remove anything
whose name suggests it's related to uboot, or any kind of backup or
recovery partition. To see how much space is free:

.. code-block:: console

    uboot> ubi info
    [ ... ]
    UBI: available PEBs:             823

Now we can make our new root volume

.. code-block:: console

    uboot> ubi create liminix -

3) transfer the root filesystem from the build system and write it
to the new volume. Paste the environment variable settings from
:file:`result/env.scr` into U-Boot, then run

.. code-block:: console

    uboot> tftpboot ''${loadaddr} result/rootfs
    uboot> ubi write ''${loadaddr} liminix $filesize

Now we have the root filesystem installed on the device. You
can even mount it and poke around using ``ubifsmount ubi0:liminix;
ubifsls  /``

4) optional: before you configure the device to boot into Liminix
automatically, you can try booting it by hand to see if it works:

.. code-block:: console

    uboot> ubifsmount ubi0:liminix
    uboot> ubifsload ''${loadaddr} boot/uimage
    uboot> bootm ''${loadaddr}

Once you've done this and you're happy with it, reset the device to
U-Boot. You don't need to recreate the volume but you do need to
repeat step 3.

5) Instructions for configuring autoboot are likely to be very
device-dependent. On the Linksys E8450/Belkin RT3200, the environment
variable `boot_production` governs what happens on a normal boot, so
you could do

.. code-block:: console

    uboot> setenv boot_production 'led $bootled_pwr on ; ubifsmount ubi0:liminix; ubifsload ''${loadaddr} boot/uimage; bootm ''${loadaddr}'

On other devices, some detective work may be needed. Try running
`printenv` and look for likely commands, try looking at the existing
boot process, maybe even try looking for documentation for that device.

6) Now you can reboot the device into Liminix

.. code-block:: console

    uboot> reset
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
          ln -s ${instructions} env.scr
       '';
    };
  };
}
