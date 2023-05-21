User Manual
###########

This manual is an early work in progress, not least because Liminix is
not yet really ready for users who are not also developers. Your
feedback to improve it is very welcome.

Installation
************

The Liminix installation process is not quite like installing NixOS on
a real computer, but some NixOS experience will nevertheless be
helpful in understanding it.  The steps are as follows:

* Decide whether you want the device to be updatable in-place (there
  are advantages and disadvantages), or if you are happy to generate
  and flash a new image whenever changes are required.

* Create a :file:`configuration.nix` describing the system you want

* Build an image

* Flash it to the device


Choosing a flavour (read-only or updatable)
===========================================

Liminix installations come in two "flavours"- read-only or in-place
updatable:

* a read-only installation can't be updated once it is flashed to your
  device, and so must be reinstalled in its entirety every time you
  want to change it.  It uses the ``squashfs`` filesystem which has
  very good compression ratios and so you can pack quite a lot of
  useful stuff onto your device.  This is good if you don't expect
  to change it often.

* an updatable installation has a writable filesystem so that you can
  update configuration, upgrade packages and install new packages over
  the network after installation. This uses the `jffs2
  <http://www.linux-mtd.infradead.org/doc/jffs2.html>`_ filesystem:
  although it does compress the data, the need to support writes means
  that it can't pack quite as small as squashfs, so you will not have
  as much space to play with.

Updatability caveats
~~~~~~~~~~~~~~~~~~~~

At the time of writing this manual the read-only squashfs support is
much more mature. Consider also that it may not be possible to perform
"larger" updates in-place even if you do opt for updatability.  If you
have (for example) an 11MB system on a 16MB device, you won't be able
to do an in-place update of something fundamental like the C library
(libc), as this will temporarily require 22MB to install all the
packages needing the new library before the packages using the old
library can be removed. A writable system will be more useful for
smaller updates such as installing a new package (perhaps you
temporarily need tcpdump to diagnose a network problem) or for
changing configuration files.

Note also that the kernel is not part of the filesystem so cannot be
updated this way. Kernel changes require a full reflash.



Creating configuration.nix
==========================


You need to create a :file:`configuration.nix` that describes your device
and the services that you want to run on it. Start by copying
:file:`vanilla-configuration.nix` and adjusting it, or look in the `examples`
directory for some pre-written configurations.

:file:`configuration.nix` conventionally describes the packages, services,
user accounts etc of the device. It does not describe the hardware
itself, which is specified separately in the build command (as you
will see below).

Your configuration may include modules: it probably *should*
include the ``standard`` module unless you understand what it
does and what happens if you leave it out.

.. code-block:: nix

    imports = [
      ./modules/standard.nix
    ]
    configuration.rootfsType = "jffs2"; # or "squashfs"



Building
========

Build Liminix using the :file:`default.nix` in the project toplevel
directory, passing it arguments for configuration and hardware. For
example:

.. code-block:: console

    nix-build -I liminix-config=./tests/smoke/configuration.nix \
     --arg device "import ./devices/qemu" -A outputs.default

In this command ``<liminix-config>`` points to your
:file:`configuration.nix`, ``device`` is the file for your hardware device
definition, and ``outputs.default`` will generate some kind of
Liminix image output appropriate to that device.

For the qemu device in this example, ``outputs.default`` is an alias
for ``outputs.vmbuild``, which creates a directory containing a
squashfs root image and a kernel. You can use the :command:`mips-vm` command to
run this.

For the currently supported hardware devices, ``outputs.default``
creates a directory containing a file called ``firmware.bin``.  This
is a raw image file that can be written directly to the firmware flash
partition.


Flashing
========


Flashing from OpenWrt (untested)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If your device is running OpenWrt then it probably has the
:command:`mtd` command installed and you can use it as follows:

.. code-block:: console

   mtd -r write /tmp/firmware_image.bin firmware

For more information, please see the `OpenWrt manual <https://openwrt.org/docs/guide-user/installation/sysupgrade.cli>`_ which may also contain (hardware-dependent) instructions on how to flash an image using the vendor firmware - perhaps even from a web interface.


Flashing from the boot monitor
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you are prepared to open the device and have a TTL serial adaptor
of some kind to connect it to, you can probably flash it using U-Boot.
This is quite hardware-specific, and sometimes involves soldering:
please refer to the Developer Manual.


Flashing from an existing Liminix system with :command:`flashcp`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The flash procedure from an existing Liminix-system is two-step.
First we reboot the device (using "kexec") into an "ephemeral"
RAM-based version of the new configuration, then when we're happy it
works we can flash the image - and if it doesn't work we can reboot
the device again and it will boot from the old image.


Building the RAM-based image
............................

To create the ephemeral image, build ``outputs.kexecboot`` instead of
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
to the old configuration it finds in flash.


Building the second (permanent) image
.....................................

While running in the kexecboot system, you can copy the permanent
image to the device with :command:`ssh`

.. code-block:: console

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


"I know my new image is good, can I skip the intemediate step?"
```````````````````````````````````````````````````````````````

In addition to giving you a chance to see if the new image works, this
two-step process ensures that you're not copying the new image over
the top of the active root filesystem. It might work, or it might
crash in surprising ways.



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



Configuration Options
*********************



Module docs will go here. This part of the doc should be autogenerated.
