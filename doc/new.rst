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
that run Liminix are unlikely to have the CPU power and disk space to
be able to build it in situ, so the build process is based around
"cross-compilation" from another computer. The build machine can be
any reasonably powerful desktop/laptop/server PC running NixOS.
Standalone Nixpkgs installations on other Linux distributions - or on
MacOS - also ought to work but are untested.


Running in Qemu
***************

You can do this without even having a router to play with.
Clone the Liminix git repository and change into its directory


.. code-block:: console

    git clone https://gti.telent.net/dan/liminix
    cd liminix

Now build Liminix

.. code-block:: console

    nix-build -I liminix-config=./examples/hellonet.nix \
     --arg device "import ./devices/qemu" -A outputs.default

In this command ``liminix-config`` points to the desired software
configuration (e.g. services, users, filesystem, secrets) and
``device`` describes the hardware (or emulated hardware) to run it on.
``outputs.default`` tells Liminix that we want the default image
output for flashing to the device: for the Qemu "hardware" it's an
alias for ``outputs.vmbuild``, which creates a directory containing a
root filesystem image and a kernel.

.. tip:: The first time you run this it may take several hours,
         because it builds all of the dependencies including a full
         MIPS gcc and library toolchain. Once those intermediate build
         products are in the nix store, subsequent builds will be much
         faster - practically instant, if nothing has changed.

Now you can try it:

.. code-block:: console

    nix-shell --run "mips-vm ./result/vmlinux ./result/rootfs"

This starts Qemu emulator with a bunch of useful options, to run
the Liminix configuration you just built.  It connects the Liminix
serial console and the `QEMU monitor
<https://www.qemu.org/docs/master/system/monitor.html>`_ to
stdin/stdout.

You should now see Linux boot messages and after a few seconds be
presented with a login prompt. You can login on the console as
``root`` (password is "secret") and poke around to see what processes are
running. To kill the emulator, press ^P (Control P) then c to enter the
"QEMU Monitor", then type ``quit`` at the ``(qemu)`` prompt.

To see that it's running network services we need to connect to its
emulated network. Start the machine again, if you had stopped it, and
open up a second terminal on your build machine. We're going to run
another virtual machine attached to the virtual network, which will
request an IP address from our Liminix system and give you a shell you
can run ssh from.

We'll use `System Rescue <https://www.system-rescue.org/>`_ in tty
mode (no graphical output) for this purpose, but if you have some
other favourite Linux Live CD ISO - or, for that matter, any other OS
image that QEMU can boot - adjust the command to suit:

.. code-block:: console

    curl https://fastly-cdn.system-rescue.org/releases/10.01/systemrescue-10.01-amd64.iso -O

    nix-shell -p qemu --run " \
    qemu-system-x86_64 \
	-echr 16 \
	-m 1024 \
	-cdrom systemrescue-10.01-amd64.iso \
	-netdev socket,mcast=230.0.0.1:1235,localaddr=127.0.0.1,id=lan \
	-device virtio-net,disable-legacy=on,disable-modern=off,netdev=lan,mac=ba:ad:3d:ea:21:01 \
	-display none -serial mon:stdio"

System Rescue displays a boot menu at which you should select the
"serial console" option, then after a few moments it boots to a root
prompt. You can now try things out:

* run :command:`ip a` and see that it's been allocated an IP address in the range 10.3.0.0/16.

* run :command:`ping 10.3.0.1` to see that the Liminix VM responds

* run :command:`ssh root@10.3.0.1` to try logging into it.

Congratulations! You have installed your first Liminix system - albeit
it has no practical use and it's not even real. The next step is to try
running it on hardware.


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
