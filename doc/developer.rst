Developer Manual
################

As a developer working on Liminix, or implementing a service or
module, you probably want to test your changes more conveniently
than by building and flashing a new image every time. This manual
documents various affordances for iteration and experiments.

In general, packages and tools that run on the "build" machine are
available in the ``buildEnv`` derivation and can most easily
be added to your environment by running :command:`nix-shell`



Emulated devices
****************

Liminix has a ``qemu`` device, which generates images suitable for
running on your build machine using the free `QEMU machine emulator <http://www.qemu.org>`_.
This is useful for developing userland without needing to keep
flashing or messing with U-Boot: it also enables testing against
emulated network peers using `QEMU socket networking <https://wiki.qemu.org/Documentation/Networking#Socket>`_,
which may be preferable to letting Liminix loose on your actual LAN.
To build it,

.. code-block:: console

    nix-build -I liminix-config=path/to/your/configuration.nix --arg device "import ./devices/qemu" -A outputs.default

In a ``buildEnv`` nix-shell, you can use the :command:`mips-vm` command
to run Qemu with appropriate options. It connects the Liminix
serial console and the `QEMU monitor  <https://www.qemu.org/docs/master/system/monitor.html>`_ to stdin/stdout. Use ^P (not ^A) to switch to the monitor.

.. code-block:: console

    nix-shell --run "mips-vm result/vmlinux result/squashfs"

If you run with ``--background /path/to/some/directory`` as the first
parameter, it will fork into the background and open Unix sockets in
that directory for console and monitor.  Use :command:`connect-vm`
(also in the ``buildEnv`` environment) to connect to either of these
sockets, and ^O to disconnect.

Networking
==========

VMs can network with each other using QEMU
socket networking.  We observe these conventions, so that we can run
multiple emulated instances and have them wired up to each other in
the right way:

* multicast 230.0.0.1:1234  : access (interconnect between router and "isp")
* multicast 230.0.0.1:1235  : lan
* multicast 230.0.0.1:1236  : world (the internet)

A VM started with :command:`mips-vm` is connected to "lan" and "access", and
the emulated border network gateway (see below) runs PPPoE and is
connected to "access" and "world".

Border Network Gateway
----------------------

In pkgs/routeros there is a derivation to install and configure
`Mikrotik RouterOS <https://mikrotik.com/software>`_ as a PPPoE access
concentrator connected to the ``access`` and ``world`` networks, so that
Liminix PPPoE client support can be tested without actual hardware.

This is made available as the :command:`routeros` command in
``buildEnv``, so you can do something like::

    mkdir ros-sockets
    nix-shell
    nix-shell$ routeros ros-sockets
    nix-shell$ connect-vm ./ros-sockets/console

to start it and connect to it. Note that by default it runs in the
background. It is connected to "access" and "world" virtual networks
and runs a PPPoE service on "access" - so a Liminix VM with a
PPPOE client can connect to it and thus reach the virtual internet.
[ check, but pretty sure this is not the actual internet ]

`Liminix does not provide RouterOS licences and it is your own
responsibility if you use this to ensure you're compliant with the
terms of Mikrotik's licencing. It may be supplemented or replaced in
time with configurations for RP-PPPoE and/or Accel PPP.`

Hardware devices
****************

How you get your image onto hardware will vary according to the
device, but is likely to involve taking it apart to add wires to
serial console pads/headers, then using U-Boot to fetch images over
TFTP.  The OpenWrt documentation has a `good explanation <https://openwrt.org/docs/techref/hardware/port.serial>`_ of what you may expect to find on
the device.


There is a rudimentary TFTP server bundled with the system which runs
from the command line, has an allowlist for client connections, and
follows symlinks, so you can have your device download images direct
from the :file:`./result` directory without exposing :file:`/nix/store/` to the
internet or mucking about copying files to :file:`/tftproot`. If the
permitted device is to be given the IP address 192.168.8.251 you might
do something like this:

.. code-block:: console

    nix-shell --run "tufted -a 192.168.8.251 result"

and then issue appropriate U-boot commands to download and flash the
image.

For a faster edit-compile-test cycle, you can build a TFTP-bootable
image instead of flashing. In your device configuration add

.. code-block:: nix

  imports = [
    ./modules/tftpboot.nix
  ];

  boot.tftp = {
    serverip = "192.168.200.148";
    ipaddr = "192.168.200.251";
  };

and then build ``outputs.tftpboot``. This creates a file in
``result/`` called ``boot.scr``, which you can copy and paste into
U-Boot to transfer the kernel and filesystem over TFTP and boot the
kernel from RAM.


Networking
==========

You probably don't want to be testing a device that might serve DHCP,
DNS and routing protocols on the same LAN as you (or your colleagues,
employees, or family) are using for anything else, because it will
interfere. You also might want to test the device against an
"upstream" connection without having to unplug your regular home
router from the internet so you can borrow the cable/fibre/DSL.

``bordervm`` is included for this purpose. You will need

* a Linux machine with a spare (PCI or USB) ethernet device which you can dedicate to Liminix

* an L2TP service such as https://www.aa.net.uk/broadband/l2tp-service/

You need to "hide" the Ethernet device from the host - for PCI this
means configuring it for VFIO passthru; for USB you need to unload the
module(s) it uses. I have this segment in configuration.nix which you
may be able to adapt:

.. code-block:: nix

  boot = {
    kernelParams = [ "intel_iommu=on" ];
    kernelModules = [
      "kvm-intel" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio"
    ];

    postBootCommands = ''
      # modprobe -i vfio-pci
      # echo vfio-pci > /sys/bus/pci/devices/0000:01:00.0/driver_override
    '';
    blacklistedKernelModules = [
      "r8153_ecm" "cdc_ether"
    ];
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="8153", OWNER="dan"
  '';

Then
you can execute :command:`run-border-vm` in a ``buildEnv`` shell,
which starts up QEMU using the NixOS configuration in
:file:`bordervm-configuration.nix`.

In this VM

* your Liminix checkout is mounted under :file:`/home/liminix/liminix`

* TFTP is listening on the ethernet device and serving
  :file:`/home/liminix/liminix`.  The server IP address is 10.0.0.1

* a PPPOE-L2TP relay is running on the same ethernet card.  When the
  connected Liminix device makes PPPoE requests, the relay spawns
  L2TPv2 Access Concentrator sessions to your specified L2TP LNS.
  Note that authentication is expected at the PPP layer not the L2TP
  layer, so the PAP/CHAP credentials provided by your L2TP service can
  be configured into your test device - bordervm doesn't need to know
  about them.

To configure bordervm, you need a file called :file:`bordervm.conf.nix`
which you can create by copying and appropriately editing  :file:`bordervm.conf-example.nix`

.. note::

    If you make changes to the bordervm configuration after executing
    :command:`run-border-vm`, you need to remove the :file:`border.qcow2` disk
    image file otherwise the changes won't get picked up.


Running tests
*************

You can run all of the tests by evaluating :file:`ci.nix`, which is the
input I use in Hydra. Note that it expects Nixpkgs stable `and` unstable
as inputs, because it builds the qemu device against both.

.. code-block:: console

    nix-build --argstr liminix `pwd`  --arg  nixpkgs "<nixpkgs>" \
     --argstr unstable `pwd`/../unstable-nixpkgs/ ci.nix

To run a single named test, use the ``-A`` flag. For example, ``-A pppoe``




Troubleshooting
***************

Diagnosing unexpectedly large images
====================================

Sometimes you can add a package and it causes the image size to balloon
because it has dependencies on other things you didn't know about. Build the
``outputs.manifest`` attribute, which is a JSON representation of the
filesystem, and you can run :command:`nix-store --query` on it.

.. code-block:: console

    nix-build -I liminix-config=path/to/your/configuration.nix \
      --arg device "import ./devices/qemu" -A outputs.manifest \
      -o manifest
    nix-store -q --tree manifest


Contributing
************

Contributions are welcome, though in these early days there may be a
bit of back and forth involved before patches are merged:
Please get in touch somehow `before` you invest a lot of time into a
code contribution I haven't asked for.  Just so I know it's expected
and you're not wasting time doing something I won't accept or have
already started on.


Nix language style
==================

This section describes some Nix language style points that we
attempt to adhere to in this repo.

* favour ``callPackage`` over raw ``import`` for calling derivations
  or any function that may generate one - any code that might need
  ``pkgs`` or parts of it.

* prefer ``let inherit (quark) up down strange charm`` over
  ``with quark``, in any context where the scope is more than a single
  expression or there is more than one reference to ``up``, ``down``
  etc.  ``with pkgs; [ foo bar baz]`` is OK,
  ``with lib; stdenv.mkDerivation { ... }`` is usually not.

* ``<liminix>`` is defined only when running tests, so don't refer to it
  in "application" code

* the parameters to a derivation are sorted alphabetically, except for
  ``lib``, ``stdenv`` and maybe other non-package "special cases"

* indentation is whatever emacs nix-mode says it is.

* where a ``let`` form defines multiple names, put a newline after the
  token ``let``, and indent each name two characters

* to decide whether some code should be a package or a module?
  Packages are self-contained - they live in ``/nix/store/eeeeeee-name``
  and don't directly change system behaviour by their presence or
  absense. modules can add to
  ``/etc`` or ``/bin`` or other global state, create services, all that
  side-effecty stuff.  Generally it should be a package unless it
  can't be.



Copyright
=========

The Nix code in Liminix is MIT-licenced (same as Nixpkgs), but the
code it combines from other places (e.g. Linux, OpenWrt) may have a
variety of licences.  I have no intention of asking for copyright
assignment: just like when submitting to the Linux kernel you retain
the copyright on the code you contribute.


Code of Conduct
===============

Please govern yourself in Liminix project venues according to the
`Code of Conduct <https://gti.telent.net/dan/liminix/src/commit/7bcf6b15c3fdddafeda13f65b3cd4a422dc52cd3/CODE-OF-CONDUCT.md>`_


Where to send patches
=====================


Liminix' primary repo is https://gti.telent.net/dan/liminix but you
can't send code there directly  because it doesn't have open registrations.

* There's a `mirror on Github <https://github.com/telent/liminix>`_ for
  convenience and visibility: you can open PRs against that

* or, you can send me your patch by email using `git send-email <https://git-send-email.io/>`_

* or in the future, some day, we will have federated Gitea using
  ActivityPub.
