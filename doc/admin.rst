System Administration
#####################

Services on a running system
****************************

* add an s6-rc cheatsheet here


Flashing and updating
*********************



Flashing from Liminix
=====================

The flash procedure from an existing Liminix-system has two steps.
First we reboot the device (using "kexec") into an "ephemeral"
RAM-based version of the new configuration, then when we're happy it
works we can flash the image - and if it doesn't work we can reboot
the device again and it will boot from the old image.


Building the RAM-based image
----------------------------

To create the ephemeral image, build ``outputs.kexecboot`` instead of
``outputs.default``.  This generates a directory containing the root
filesystem image and kernel, along with an executable called `kexec`
and a `boot.sh` script that runs it with appropriate arguments.

For example

.. code-block:: console

   nix-build -I liminix-config=./examples/arhcive.nix \
     --arg device "import ./devices/gl-ar750"
     -A outputs.kexecboot && \
     (tar chf - result | ssh root@the-device tar -C /run -xvf -)

and then login to the device and run

.. code-block:: console

   cd /run/result
   sh ./boot.sh .


This will load the new kernel and map the root filesystem into a RAM
disk, then start executing the new kernel. *This is effectively a
reboot - be sure to close all open files and finish anything else
you were doing first.*

If the new system crashes or is rebooted, then the device will revert
to the old configuration it finds in flash.


Building the second (permanent) image
-------------------------------------

While running in the kexecboot system, you can build the permanent
image and copy it to the device with :command:`ssh`

.. code-block:: console

   build-machine$ nix-build -I liminix-config=./examples/arhcive.nix \
     --arg device "import ./devices/gl-ar750"
     -A outputs.default && \
     (tar chf - result | ssh root@the-device tar -C /run -xvf -)

   build-machine$ tar chf - result/firmware.bin | \
    ssh root@the-device tar -C /run -xvf -

Next you need to connect to the device and locate the "firmware"
partition, which you can do with a combination of :command:`dmesg`
output and the contents of :file:`/proc/mtd`

.. code-block:: console

   <5>[    0.469841] Creating 4 MTD partitions on "spi0.0":
   <5>[    0.474837] 0x000000000000-0x000000040000 : "u-boot"
   <5>[    0.480796] 0x000000040000-0x000000050000 : "u-boot-env"
   <5>[    0.487056] 0x000000050000-0x000000060000 : "art"
   <5>[    0.492753] 0x000000060000-0x000001000000 : "firmware"

   # cat /proc/mtd
   dev:    size   erasesize  name
   mtd0: 00040000 00001000 "u-boot"
   mtd1: 00010000 00001000 "u-boot-env"
   mtd2: 00010000 00001000 "art"
   mtd3: 00fa0000 00001000 "firmware"
   mtd4: 002a0000 00001000 "kernel"
   mtd5: 00d00000 00001000 "rootfs"

Now run (in this example)

.. code-block:: console

   flashcp -v firmware.bin /dev/mtd3


"I know my new image is good, can I skip the intermediate step?"
----------------------------------------------------------------

In addition to giving you a chance to see if the new image works, this
two-step process ensures that you're not copying the new image over
the top of the active root filesystem. Sometimes it works, but you
will at least need physical access to the device to power-cycle it
because it will be effectively frozen afterwards.


Flashing from the boot monitor
==============================

If you are prepared to open the device and have a TTL serial adaptor
of some kind to connect it to, you can probably use U-Boot and a TFTP
server to download and flash the image.  This is quite
hardware-specific, and sometimes involves soldering: please refer
to the :ref:`development manual <tftp server>`.


Flashing from OpenWrt
=====================

.. CAUTION:: Untested! A previous version of these instructions
	     (without the -e flag) led to bricking the device
	     when flashing a jffs2 image. If you are reading
	     this message, nobody has yet reported on whether the
	     new instructions are any better.

If your device is running OpenWrt then it probably has the
:command:`mtd` command installed. After transferring the image onto the
device using e.g. :command:`ssh`,  you can run it as follows:

.. code-block:: console

   mtd -e -r write /tmp/firmware.bin firmware

The options to this command are for "erase before writing" and "reboot
after writing". 
   
For more information, please see the `OpenWrt manual <https://openwrt.org/docs/guide-user/installation/sysupgrade.cli>`_ which may also contain (hardware-dependent) instructions on how to flash an image using the vendor firmware - perhaps even from a web interface.

Updating an installed system (JFFS2)
************************************


Adding packages
===============

If your device is running a JFFS2 root filesystem, you can build
extra packages for it on your build system and copy them to the
device: any package in Nixpkgs or in the Liminix overlay is available
with the ``pkgs`` prefix:

.. code-block:: console

    nix-build -I liminix-config=./my-configuration.nix \
     --arg device "import ./devices/mydevice" -A pkgs.tcpdump

    nix-shell -p min-copy-closure root@the-device result/

Note that this only copies the package to the device: it doesn't update
any profile to add it to ``$PATH``


Rebuilding the system
=====================

:command:`liminix-rebuild` is the Liminix analogue of :command:`nixos-rebuild`, although its operation is a bit different because it expects to run on a build machine and then copy to the host device. Run it with the same ``liminix-config`` and ``device`` parameters as you would run :command:`nix-build`, and it will build any new/changed packages and then copy them to the device using SSH. For example:

.. code-block:: console

     liminix-rebuild root@the-device  -I liminix-config=./examples/rotuer.nix --arg device "import ./devices/gl-ar750"

This will

* build anything that needs building
* copy new or changed packages to the device
* reboot the device

It doesn't delete old packages automatically: to do that run
:command:`min-collect-garbage`, which will delete any packages not in
the current system closure. Note that Liminix does not have the NixOS
concept of environments or generations, and there is no way back from
this except for building the previous configuration again.


Caveats
~~~~~~~

* it needs there to be enough free space on the device for all the new
  packages in addition to all the packages already on it - which may be
  a problem if a lot of things have changed (e.g. a new version of
  nixpkgs).

* it cannot upgrade the kernel, only userland
