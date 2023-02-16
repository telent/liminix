Developer Manual
################

As a developer working on Liminix, or implementing a service or
module, you probably want to test your changes more conveniently
than by building and flashing a new image every time. This manual
documents various affordances for iteration and experiments.

In general, packages and tools that run on the "build" machine are
available in the ``buildEnv`` derivation.

.. code-block:: console

    nix-shell -A buildEnv --arg device '(import ./devices/qemu)'


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

    NIX_PATH=nixpkgs=../nixpkgs:$NIX_PATH nix-build -I liminix-config=path/to/your/configuration.nix --arg device "import ./devices/qemu" -A outputs.default

In a ``buildEnv`` nix-shell, you can use the ``mips-vm`` command
to run Qemu with appropriate options. It connects the Liminix
serial console and the `QEMU monitor  <https://www.qemu.org/docs/master/system/monitor.html>`_ to stdin/stdout. Use ^P (not ^A) to switch to the monitor.

.. code-block:: console

    nix-shell -A buildEnv --arg device '(import ./devices/qemu)' --run "mips-vm result/vmlinux result/squashfs"

If you run with ``--background /path/to/some/directory`` as the first
parameter, it will fork into the background and open Unix sockets in
that directory for console and monitor.  Use ``connect-vm`` (also in the
``buildEnv`` environment) to connect to either of these sockets, and ^O
to disconnect.

Networking
==========

VMs can network with each other using QEMU
socket networking.  We observe these conventions, so that we can run
multiple emulated instances and have them wired up to each other in
the right way

* multicast 230.0.0.1:1234  : access (interconnect between router and "isp")
* multicast 230.0.0.1:1235  : lan
* multicast 230.0.0.1:1236  : world (the internet)

A VM started with ``mips-vm`` is connected to "lan" and "access", and
the emulated border network gateway (see below) runs PPPoE and is
connected to "access" and "world".

Border Network Gateway
----------------------

In pkgs/routeros there is a derivation to install and configure
`Mikrotik RouterOS <https://mikrotik.com/software>`_ as a PPPoE access
concentrator connected to the ``access`` and ``world`` networks, so that
Liminix PPPoE client support can be tested without actual hardware.

This is made available as the ``routeros`` command in ``buildEnv``, so you
can do something like::

    mkdir ros-sockets
    nix-shell -A buildEnv --arg device '(import ./devices/qemu)'
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
TFTP.

There is a rudimentary TFTP server bundled with the system which runs
from the command line, has an allowlist for client connections, and
follows symlinks, so you can have your device download images direct
from the ``./result`` directory without exposing ``/nix/store/`` to the
internet or mucking about copying files to ``/tftproot``. If the
permitted device is to be given the IP address 192.168.8.251 you might
do something like this:

.. code-block:: console

    nix-shell -A buildEnv --arg device '(import ./devices/qemu)' \
	 --run "tufted -a 192.168.8.251 result"

and then issue appropriate U-boot commands to download and flash the
image.

For quicker development cycle, you can build a TFTP-bootable image
instead of flashing. [ .... add this bit ....]


Running tests
*************

You can run all of the tests by evaluating ``ci.nix``, which is the
input I use in Hydra. Note that it expects Nixpkgs stable `and` unstable
as inputs, because it builds the qemu device against both.

.. code-block:: console

    nix-build --argstr liminix `pwd`  --arg  nixpkgs "<nixpkgs>" \
     --argstr unstable `pwd`/../unstable-nixpkgs/ ci.nix

or to run a named test, use the ``-A`` flag. For example, ``-A pppoe``




Troubleshooting
***************

Diagnosing unexpectedly large images
====================================

Sometimes you can add a package and it causes the image size to balloon
because it has dependencies on other things you didn't know about. Build the
``outputs.manifest`` attribute, which is a JSON representation of the
filesystem, and you can run ``nix-store --query`` on it.::

    NIX_PATH=nixpkgs=../nixpkgs:$NIX_PATH nix-build -I liminix-config=path/to/your/configuration.nix --arg device "import ./devices/qemu" -A outputs.manifest -o manifest
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

In an attempt to keep this more consistent than NixWRT ended up being,
here is a Nix language style guide for this repo.

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

Please govern yourself in Liminix project venues according to the guidance in the `geekfeminism "Community Anti-harassment Policy" <https://geekfeminism.wikia.org/wiki/Community_anti-harassment/Policy>`_.


Where to send patches
=====================


Liminix' primary repo is https://gti.telent.net/dan/liminix but that
doesn't help you much, because it doesn't have open registrations.

* There's a `mirror on Github <https://github.com/telent/liminix>`_ for
  convenience and visibility: you can open PRs against that

* or, you can send me your patch by email using `git send-email <https://git-send-email.io/>`_

* or in the future, some day, we will have federated Gitea using
  ActivityPub.
