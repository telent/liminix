{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.boot.tftp;
  instructions = pkgs.writeText "flash.scr" ''
    setenv serverip ${cfg.serverip}
    setenv ipaddr ${cfg.ipaddr}
    setenv loadaddr ${lib.toHexString cfg.loadAddress}
    tftpboot $loadaddr result/rootfs
    ubi write $loadaddr liminix $filesize
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

3) transfer the root filesystem from the build system and write it to
the new volume. Paste the contents of :file:`result/flash.scr` one line at a time
into U-Boot:

.. code-block:: console

    uboot> setenv serverip 10.0.0.1
    uboot> setenv ipaddr 10.0.0.8
    uboot> setenv loadaddr 4007FF28
    uboot> tftpboot $loadaddr result/rootfs
    uboot> ubi write $loadaddr liminix $filesize

Now we have the root filesystem installed on the device. You
can even mount it and poke around using :command:`ubifsmount ubi0:liminix; ubifsls  /`

4) optional: before you configure the device to boot into Liminix
automatically, you can try booting it by hand to see if it works:

.. code-block:: console

    uboot> ubifsmount ubi0:liminix
    uboot> ubifsload ''${loadaddr} boot/fit
    uboot> bootm ''${loadaddr}

Once you've done this and you're happy with it, reset the device to
return to U-Boot.

5) Instructions for configuring autoboot are likely to be very
device-dependent and you should consult the Liminix documentation for
your device.  (If you're bringing up a new device, some detective work
may be needed. Try running `printenv` and trace through the flow of
execution from (probably) :command:`$bootcmd` and look for a suitable
variable to change)

6) Now you can reboot the device into Liminix

.. code-block:: console

    uboot> reset
      '';
    };
  };

  config.system.outputs.ubimage =
    assert config.rootfsType == "ubifs";
    let o = config.system.outputs; in
    pkgs.runCommand "ubimage" {} ''
      mkdir $out
      cd $out
      ln -s ${o.rootfs} rootfs
      ln -s ${instructions} flash.scr
   '';
}
