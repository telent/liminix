Installation
############

Hardware devices vary wildly in their affordances for installing new
operating systems, so it should be no surprise that the Liminix
installation procedure is hardware-dependent. This section contains
generic instructions, but please refer to the documentation for your
device to find whether and how well they apply.


Building a firmware image
*************************

Liminix uses the Nix language to provide congruent configuration
management.  This means that to change anything about the way in
which a Liminix system works, you make that change in
your :file:`configuration.nix` (or one of the other files it references),
and rerun :command:`nix-build` to action
the change. It is not possible (at least, without shenanigans) to make
changes by logging into the device and running imperative commands
whose effects may later be overridden: :file:`configuration.nix`
always describes the entire system and can be used to recreate that
system at any time.  You can usefully keep it under version control.

If you are familiar with NixOS, you will notice some similarities
between NixOS and Liminix configuration, and also some
differences. Sometimes the differences are due to the
resource-constrained devices we deploy onto, sometimes due to
differences in the uses these devices are put to.

For a more full description of how to configure Liminix, see
:ref:`configuration`. Assuming for the moment that you want a typical
home wireless gateway/router, the best way to get started is to copy
:file:`examples/rotuer.nix` and edit it for your requirements.


.. code-block:: console

    $ cp examples/rotuer.nix configuration.nix
    $ vi configuration.nix # other editors are available 
    $ # adjust this next command for your hardware device
    $ nix-build -I liminix-config=./configuration.nix \
     --arg device "import ./devices/gl-mt300a" -A outputs.default

Usually  (not always, *please check the documentation for your device*)
this will leave you with a file :file:`result/firmware.bin`
which you now need to flash to the device.


Flashing from the boot monitor (TFTP install)
*********************************************

If you are prepared to open the device and have a TTL serial adaptor
of some kind to connect it to, you can probably use U-Boot and a TFTP
server to download and flash the image.

This is quite hardware-specific and may even involve soldering - see
the documention for your device. However, it is in some ways the most
"reliable" option: if you can see what's happening (or not happening)
in early boot, the risk of "bricking" is substantially reduced and you
have options for recovering if you misstep or flash a bad image.


.. _serial:

U-Boot and serial shenanigans
=============================

Every device that we have so far encountered in Liminix uses `U-Boot,
the "Universal Boot Loader" <https://docs.u-boot.org/en/latest/>`_ so
it's worth knowing a bit about it. "Universal" is in this context a
bit of a misnomer, though: encountering *mainline* U-Boot is very rare
and often you'll find it is a fork from some version last updated
in 2008. Upgrading U-Boot is more or less complicated depending on the
device and is outside scope for Liminix.

To speak to U-Boot on your device you'll usually need a serial
connection to it.  This typically involves opening the box, locating
the serial header pins (TX, RX and GND) and connecting a USB TTL
converter to them.

The Rolls Royce of USB/UART cables is the `FTDI cable
<https://cpc.farnell.com/ftdi/ttl-232r-rpi/cable-debug-ttl-232-usb-rpi/dp/SC12825?st=usb%20to%20uart%20cable>`_,
but there are cheaper alternatives based on the PL2303 and CP2102 chipsets -   or you could even 
get creative and use the `UART GPIO pins <https://pinout.xyz/>`_ on a Raspberry Pi. Whatever you do, make sure
that the voltages are compatible: if your device is 3.3V (this is
typical but not universal), you don't want to be sending it 5v or
(even worse) 12v.

Run a terminal emulator such as Minicom on the computer at other end
of the link. 115200 8N1 is the typical speed.

.. NOTE::

   TTL serial connections often have no flow control and
   so don't always like having massive chunks of text pasted into
   them - and U-Boot may drop characters while it's busy. So don't
   do that.

   If using Minicom, you may find it helps to bring up the "Termimal
   settings" dialog (C^A T), then configure "Newline tx delay" to
   some small but non-zero value.

When you turn the router on you should be greeted with some messages
from U-Boot, followed by the instruction to hit some key to stop
autoboot. Do this and you will get to the prompt. If you didn't see
anything, the strong likelihood is that TX and RX are the wrong way
around. If you see garbage, try a different speed.

Interesting commands to try first in U-Boot are :command:`help` and
:command:`printenv`.

You will also need to configure a TFTP server on a network that's
accessible to the device: how you do that will vary according to which
TFTP server you're using and so is out of scope for this document.



Building and installing the image
=================================

Follow the device-specific instructions for "TFTP install": usually,
the steps are 

* build the `outputs.mtdimage` output
* copy :file:`result/firmware.bin` to your TFTP server
* copy/paste the commands in :file:`result/flash.scr` one at a time into the U-Boot command line
* reset the device

You should now see messages from U-Boot, then from the Linux kernel
and eventually a shell prompt.

.. NOTE:: Before you reboot, check which networks the device is
          plugged into, and disconnect as necessary. If you've just
          installed a DHCP server or anything similar that responds to
          broadcasts, you may not want it to do that on the network
          that you temporarily connected it to for installing it.



Flashing from OpenWrt
*********************

.. CAUTION:: Untested! A previous version of these instructions
	     (without the -e flag) led to bricking the device
	     when flashing a jffs2 image. If you are reading
	     this message, nobody has yet reported on whether the
	     new instructions are any better.

If your device is running OpenWrt then it probably has the
:command:`mtd` command installed. Build the `outputs.mtdimage` output
(as you would for a TFTP install) and then transfer
:file:`result/firmware.bin` onto the device using e.g.
:command:`scp`. Now flash as follows:

.. code-block:: console

   mtd -e -r write /tmp/firmware.bin firmware

The options to this command are for "erase before writing" and "reboot
after writing".

For more information, please see the `OpenWrt manual <https://openwrt.org/docs/guide-user/installation/sysupgrade.cli>`_ which may also contain (hardware-dependent) instructions on how to flash an image using the vendor firmware - perhaps even from a web interface.


Flashing from Liminix
*********************

If the device is already running Liminix and has been configured with
:command:`levitate`, you can use that to safely flash your new image.
Refer to :ref:`levitate` for an explanation.

If the device is running Liminix but doesn't have :command:`levitate`
your options are more limited. You may attempt to use
:command:`flashcp` but it doesn't always work: as it copies the new
image over the top of the active root filesystem, surprise may ensue.
Consider instead using a serial connection: you may need one anyway
after trying flashcp if it corrupts the image.

flashcp (not generally recommended)
===================================

Connect to the device and locate the "firmware" partition, which you
can do with a combination of :command:`dmesg` output and the contents
of :file:`/proc/mtd`

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

Copy :file:`result/firmware.bin` to the device and now run (in this
example)

.. code-block:: console

   flashcp -v firmware.bin /dev/mtd3


