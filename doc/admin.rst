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


.. _rebuilding the system:

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

.. _levitate:  

Reinstalling on a running system
********************************

Liminix is initially installed from a monolithic
:file:`firmware.bin` - and unless you're running a writable
filesystem, the only way to update it is to build and install a whole
new :file:`firmware.bin`.  However, you probably would prefer not to
have to remove it from its installation site, unplug it from the
network and stick serial cables in it all over again.

It is not (generally) safe to install a new firmware onto the flash
partitions that the active system is running on. To address this we
have :command:`levitate`, which a way for a running Liminix system to
"soft restart" into a ramdisk running only a limited set of services,
so that the main partitions can then be safely flashed.



Configuration
=============

Levitate *needs to be configured when you create the initial system*
to specify which services/packages/etc to run in maintenance
mode. Most likely you want to configure a network interface and an ssh
for example so that you can login to reflash it.

.. code-block:: nix

  defaultProfile.packages = with pkgs; [
    ...
    (levitate.override {
      config  = {
        services = {
          inherit (config.services) dhcpc sshd watchdog;
        };
        defaultProfile.packages = [ mtdutils ];
        users.root = config.users.root;
      };
    })
  ];
  		


Use
===

Connect (with ssh, probably) to the running Liminix system that you
wish to upgrade.

.. code-block:: console

  bash$ ssh root@the-device
  
Run :command:`levitate`. This takes a little while (perhaps a few
tens of seconds) to execute, and copies all config required for
maintenance mode to :file:`/run/maintenance`.
  
.. code-block:: console
  
  # levitate 
  
Reboot into maintenance mode. You will be logged out
  
.. code-block:: console

  # reboot
  
Connect to the device again - note that the ssh host key will have changed.
  
.. code-block:: console

  # ssh -o UserKnownHostsFile=/dev/null root@the-device
  
Check we're in maintenance mode
  
.. code-block:: console

  # cat /etc/banner 
  
  LADIES AND GENTLEMEN WE ARE FLOATING IN SPACE
  
  Most services are disabled. The system is operating
  with a ram-based root filesystem, making it safe to
  overwrite the flash devices in order to perform
  upgrades and maintenance.
  
  Don't forget to reboot when you have finished.
  
Perform the upgrade, using flashcp. This is an example,
your device will differ
   
.. code-block:: console

  # cat /proc/mtd 
  dev:    size   erasesize  name
  mtd0: 00030000 00010000 "u-boot"
  mtd1: 00010000 00010000 "u-boot-env"
  mtd2: 00010000 00010000 "factory"
  mtd3: 00f80000 00010000 "firmware"
  mtd4: 00220000 00010000 "kernel"
  mtd5: 00d60000 00010000 "rootfs"
  mtd6: 00010000 00010000 "art"
  # flashcp -v firmware.bin mtd:firmware

All done
  
.. code-block:: console

  # reboot

