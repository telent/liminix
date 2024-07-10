System Administration
#####################

Services on a running system
****************************

Liminix services are built on s6-rc, which is itself layered on s6.
See configuration / services node for how to specify them.



.. list-table:: Service management quick reference
   :widths: 55 45
   :header-rows: 1
   
   * - What
     - How
   * - List all running services
     - ``s6-rc -a list``
   * - List all services that are **not** running
     - ``s6-rc -da list``
   * - List services that ``wombat`` depends on
     - ``s6-rc-db dependencies wombat``
   * - ... transitively
     - ``s6-rc-db all-dependencies wombat``
   * - List services that depend on service ``wombat``
     - ``s6-rc-db -d dependencies wombat``
   * - ... transitively
     - ``s6-rc-db -d all-dependencies wombat``
   * - Stop service ``wombat`` and everything depending on it
     - ``s6-rc -d change wombat``
   * - Start service ``wombat`` (but not any services depending on it)
     - ``s6-rc -u change wombat``
   * - Start service ``wombat`` and all* services depending on it
     - ``s6-rc-up-tree wombat``

:command:`s6-rc-up-tree` brings up a service and all services that
depend on it, except for any services that depend on a "controlled"
service that is not currently running. Controlled services are not
started at boot time but in response to external events (e.g. plugging
in a particular piece of hardware) so you probably don't want to be
starting them by hand if the conditions aren't there.

A service may be **up** or **down** (there are no intermediate states
like "started" or "stopping" or "dying" or "cogitating"). Some (but
not all) services have "readiness" notifications: the dependents of a
service with a readiness notification won't be started until the
service signals (by writing to a nominated file descriptor) that it's
prepared to start work. Most services defined by Liminix also have a
``timeout-up`` parameter, which means that if a service has readiness
notifications and doesn't become ready in the allotted time (defaults
20 seconds) it will be terminated and its state set to **down**.

If the process providing a service dies, it will be restarted
automatically. Liminix does not automatically set it to **down**.

(If the process providing a service dies without ever notifying
readiness, Liminix will restart it as many times as it has to until the
timeout period elapses, and then stop it and mark it down.)

Controlled services
===================

**Controlled** services are those which are started/stopped on demand
by a **controller** (another service) instead of being started at boot
time.  For example:

* ``svc.uevent-rule.build`` creates a controlled service which is
  active when a particular hardware device (identified by uevent/sysfs
  directory) is present.

* :command:`s6-rc-round-robin` can be used in a service controller to
  invoke two or more services in turn, running the next one when the
  process providing the previous one exits. We use this for failover
  from one network connection to a backup connection, for example.

The Configuration section of the manual describes this in more detail.

Logs
====

Logs for all services are collated into :file:`/run/uncaught-logs/current`.
The log file is rotated when it reaches a threshold size, into another
file in the same directory whose name contains a TAI64 timestamp.

Each log line is prefixed with a TAI64 timestamp and the name of the
service, if it is a longrun. If it is a oneshot, a timestamp and the
name of some other service. To convert the timestamp into a
human-readable format, use :command:`s6-tai64nlocal`.

.. code-block:: console

  # ls -l /run/uncaught-logs/
  -rw-r--r--    1         0 lock
  -rw-r--r--    1         0 state
  -rwxr--r--    1     98059 @4000000000025cb629c311ac.s
  -rwxr--r--    1     98061 @40000000000260f7309c7fb4.s
  -rwxr--r--    1     98041 @40000000000265233a6cc0b6.s
  -rwxr--r--    1     98019 @400000000002695d10c06929.s
  -rwxr--r--    1     98064 @4000000000026d84189559e0.s
  -rwxr--r--    1     98055 @40000000000271ce1e031d91.s
  -rwxr--r--    1     98054 @400000000002760229733626.s
  -rwxr--r--    1     98104 @4000000000027a2e3b6f4e12.s
  -rwxr--r--    1     98023 @4000000000027e6f0ed24a6c.s
  -rw-r--r--    1     42374 current
  
  # tail -2 /run/uncaught-logs/current 
  @40000000000284f130747343 wan.link.pppoe Connect: ppp0 <--> /dev/pts/0
  @40000000000284f230acc669 wan.link.pppoe sent [LCP ConfReq id=0x1 <asyncmap 0x0> <magic 0x667a9594> <pcomp> <accomp>]
  # tail -2 /run/uncaught-logs/current  | s6-tai64nlocal 
  1970-01-02 21:51:45.828598156 wan.link.pppoe sent [LCP ConfReq id=0x1 <asyncmap 0x0> <magic 0x667a9594> <pcomp> <accom
  p>]
  1970-01-02 21:51:48.832588765 wan.link.pppoe sent [LCP ConfReq id=0x1 <asyncmap 0x0> <magic 0x667a9594> <pcomp> <accom
  p>]




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
to :ref:`serial`.


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
-------

* it needs there to be enough free space on the device for all the new
  packages in addition to all the packages already on it - which may be
  a problem if a lot of things have changed (e.g. a new version of
  nixpkgs).

* it cannot upgrade the kernel, only userland
