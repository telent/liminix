User Manual
###########

This manual is an early work in progress, not least because Liminix is
not yet ready for users who are not also developers.

Configuring for your use case
*****************************

You need to create a ``configuration.nix`` that describes your router
and the services that you want to run on it. Start by copying
``vanilla-configuration.nix`` and adjusting it, or look in the `examples`
directory for some pre-written configurations.

If you want to create a configuration that can be installed on
a hardware device, be sure to include the "flashable" module.

.. code-block: nix

  imports = [
    ./modules/flashable.nix
  ]



Building and flashing
*********************

An example command to build Liminix might look like this:

.. code-block:: console

    nix-build -I liminix-config=./tests/smoke/configuration.nix \
     --arg device "import ./devices/qemu" -A outputs.default

In this command ``<liminix-config>`` points to your
``configuration.nix``, ``device`` is the file for your hardware device
definition, and ``outputs.default`` will generate some kind of
Liminix image output appropriate to that device.

For the qemu device in this example, ``outputs.default`` is an alias
for ``outputs.vmbuild``, which creates a directory containing a
squashfs root image and a kernel. You can use the `mips-vm` command to
run this.

For the currently supported hardware devices, ``outputs.default``
creates a directory containing a file called ``firmware.bin``.  This
is a raw image file that can be written directly to the firmware flash
partition.


Flashing with :command:`flashcp`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This requires an existing Liminix system, or perhaps some other
operating system on the device which provides the :command:`flashcp`
command. You need to locate the "firmware" partition, which you can do
with a combination of :command:`dmesg` output and the contents of
:file:`/proc/mtd`

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

Then you can copy the image to the device with :command:`ssh`

.. code-block:: console

   build-machine$ tar chf - result/firmware.bin | \
    ssh root@the-device tar -C /run -xvf -

and then connect to the device and run


.. code-block:: console

   flashcp firmware.bin /dev/mtd3



Flashing from OpenWrt (untested)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If your device is running OpenWrt then it probably has the
:command:`mtd` command installed and you can use it as follows:

.. code-block:: console

   mtd -r write /tmp/firmware_image.bin firmware

For more information, please see the `OpenWrt manual <https://openwrt.org/docs/guide-user/installation/sysupgrade.cli>`_


Flashing from the boot monitor
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you are prepared to open the device and have a TTL serial adaptor
or some kind to connect it to, you can probably flash it using U-Boot.
This is quite hardware-specific: please refer to the Developer Manual.



Updates to running devices
**************************

To mitigate the risk of flashing a new configuration and potentially
render the device unresponsive if the configuration is unbootable or
doesn't bring up a network device, Liminix has a
"try before write" mode.

To test a configuration without writing it to flash, import the
``kexecboot`` module and build ``outputs.kexecboot`` instead of
``outputs.default``.  This generates a directory containing the root
filesystem image and kernel, along with an executable called `kexec`
and a `boot.sh` script that runs it with appropriate arguments.

For example

.. code-block:: console

   nix-build --show-trace -I liminix-config=./examples/arhcive.nix \
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
to the old configuration it finds in flash. Thus, by combining kexec
boot with a hardware watchdog you can try new images with very little
chance of bricking anything. When you are happy that the new
configuration is correct, build and flash a flashable image of it.



Module options (tbd)
**************



Foo module
==========

Module docs will go here. This part of the doc should be autogenerated.


Bar module
==========

Baz module
==========

Quuz net device
===============
