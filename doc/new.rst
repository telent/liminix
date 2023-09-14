Getting Started
###############

Liminix is very configurable, which can make it initially daunting
especially if you're learning Nix or Linux or networking concepts at
the same time. In this section we build some "worked example" Liminix
images to introduce the concepts. If you follow the examples exactly,
they should work. If you change things as you go along, they may work
differently or not at all, but the experience should be educational
either way.


.. warning:: The first example we will look at runs under emulation,
	     so there is no danger of bricking your hardware
	     device. For the second example you may (if you have
	     appropriate hardware and choose to do so) flash the
	     configuration onto an actual router. There is always a
	     risk of rendering the device unbootable when you do this,
	     and various ways to recover depending on what went wrong.
	     We'll write more about that at the appropriate point


Requirements
************

You will need a reasonably powerful computer running Nix.  Devices
that run Liminix are unlikely tohave the CPU power and disk space to
be able to build it in situ, so the build process is based around
"cross-compilation" from another computer. The build machine can be
any reasonably powerful desktop/laptop/server PC running NixOS.
Standalone Nixpkgs installations on other Linux distribuions or MacOS
also ought to work (but I haven't tested that configuration)


Running in Qemu
***************

Clone the Liminix git repository and change into its directory


.. code-block:: console

    git clone https://gti.telent.net/dan/liminix
    cd liminix

Now build Liminix

.. code-block:: console

    nix-build -I liminix-config=./examples/hellonet.nix \
     --arg device "import ./devices/qemu" -A outputs.default

In this command ``liminix-config`` points to the configuration for the
device (services, users, filesystem, secrets) and ``device`` is the
file for your hardware device definition.  ``outputs.default`` tells
Liminix to build the appropriate  image output appropriate to
flash to the hardware device: for the qemu "hardware" it's an alias
for ``outputs.vmbuild``, which creates a directory containing a root
filesystem image and a kernel.

.. tip:: The first time you run this it may take several hours,
         because it builds all of the dependencies including a full
         MIPS gcc and library toolchain. Once those intermediate build
         products are in the nix store, subsequent builds will be much
         faster - practically instant, if nothing has changed.

Now you can try it:

.. code-block:: console

    nix-shell --run "mips-vm ./result/vmlinux ./result/rootfs"

This starts the Qemu emulator to run the Liminix configuration you
just built.  It connects the Liminix serial console and the `QEMU
monitor <https://www.qemu.org/docs/master/system/monitor.html>`_ to
stdin/stdout. Use ^P (not ^A) to switch to the monitor.

You should now see Linux boot messages and after a few seconds be
presented with a login prompt. You can login on the console as
``root`` (no password) and poke around to see what processes are
running.  Run ``shutdown`` to shut it down cleanly, or press ^P then
type ``exit`` at the monitor to stop it suddenly.

To see that it running an ssh service we need to connect to its
emulated network. Start the machine again, if you had stopped it,
and open up a second terminal on your build machine. We're going to
run another virtual machine attached to the virtual network, which will
request an IP address from our Liminix system and give you a shell
you can run ssh from.




- using modules

  - link to module reference

- creating custom services

  - longrun or oneshot
  - dependencies
  - outputs

- creating your own modules

- hacking on Liminix itself

- contributing

- external links and resources

- module reference

- hardware device reference
