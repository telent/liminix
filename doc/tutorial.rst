Tutorial
########

Liminix is very configurable, which can make it initially quite
daunting - especially if you're learning Nix or Linux or networking
concepts at the same time. In this section we build some "worked
example" Liminix images to introduce the concepts. If you follow the
examples exactly, they should work. If you change things as you go
along, they may work differently or not at all, but the experience
should be educational either way.


Requirements
************

You will need a reasonably powerful computer running Nix.  Target
devices for Liminix are unlikely to have the CPU power and disk space
to be able to build it in situ, so the build process is based around
"cross-compilation" from another computer. The build machine can be
any reasonably powerful desktop/laptop/server PC running NixOS.
Standalone Nixpkgs installations on other Linux distributions - or on
MacOS, or even in a Docker container - also ought to work but are
untested.


Running in Qemu
***************

You can try out Liminix without even having a router to play with.
Clone the Liminix git repository and change into its directory


.. code-block:: console

    git clone https://gti.telent.net/dan/liminix
    cd liminix

Now build Liminix

.. code-block:: console

    nix-build -I liminix-config=./examples/hello-from-qemu.nix \
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

    ./result/run.sh

This starts the Qemu emulator with a bunch of useful options, to run
the Liminix configuration you just built.  It connects the emulated
device's serial console and the `QEMU monitor
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

We use `System Rescue <https://www.system-rescue.org/>`_ in tty
mode (no graphical output) for this example, but if you have some
other favourite Linux Live CD ISO - or, for that matter, any other OS
image that QEMU can boot - adjust the command to suit.

Download the System Rescue ISO:

.. code-block:: console

    curl https://fastly-cdn.system-rescue.org/releases/10.01/systemrescue-10.01-amd64.iso -O

and run it

.. code-block:: console

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

Installing on hardware
**********************

For the next example, we're going to install onto an actual hardware
device.  These steps have been tested using a GL-iNet GL-MT300A, which
has been chosen for the purpose because it's cheap and easy to
unbrick if necessary

.. warning:: There is always a risk of rendering your device
	     unbootable by flashing it with an image that doesn't
	     work. The GL-MT300A has a builtin "debrick" procedure in
	     the boot monitor and is also comparatively simple to
	     attach serial cables to (soldering not required), so it
	     is lower-risk than some devices.  Using some other
	     Liminix-supported MIPS hardware device also *ought* to
	     work here, but you accept the slightly greater bricking
	     risk if it doesn't.

You may want to acquire a `USB TTL serial cable
<https://cpc.farnell.com/ftdi/ttl-232r-rpi/cable-debug-ttl-232-usb-rpi/dp/SC12825?st=usb%20to%20uart%20cable>`_
when you start working with Liminix on real hardware. You
won't *need* it for this example, assuming it works, but it
allows you
to see the boot monitor and kernel messages, and to login directly to
the device if for some reason it doesn't bring its network up. You have options
here: the FTDI-based cables are the Rolls Royce of serial cables,
whereas the ones based on PL2303 and CP2102 chipsets are cheaper but
also fussier - or you could even get creative and use e.g. a
`Raspberry Pi <https://pinout.xyz/#>`_ or other SBC with a UART and
TX/RX/GND header pins. Make sure that the voltages are compatible:
this is a 3.3v device and you don't want to be sending it 5v or (even
worse) 12v.

Now we can build Liminix. Although we could use the same example
configuration as we did for Qemu, you might not want to plug a DHCP
server into your working LAN because it will compete with the real
DHCP service. So we're going to use a different configuration with a
DHCP client: this is :file:`examples/hello-from-mt300.nix`

It's instructive to compare the two configurations:

.. code-block:: console

    diff -u examples/hello-from-qemu.nix examples/hello-from-mt300.nix

You'll see a new ``boot.tftp`` stanza which you can ignore,
``services.dns`` has been removed, and the static IP address allocation
has been replaced by a ``dhcp.client`` service.

.. code-block:: console

    nix-build -I liminix-config=./examples/hello-from-mt300.nix \
     --arg device "import ./devices/gl-mt300a" -A outputs.default

.. tip:: The first time you run this it may take several hours.
         Again? Yes, even if you ran the previous example. Qemu is
         set up as a big-endian system whereas the MediaTek SoC
         on this device is little-endian - so it requires building
         all of the dependencies including an entirely different
         MIPS gcc and library toolchain to the other one.

This time in :file:`result/` you will see a bunch of files. Most of
them you can ignore for the moment, but :file:`result/firmware.bin` is
the firmware image you can flash.


Flashing
========

Again, there are a number of different ways you could do this: using
TFTP with a serial cable, through the stock firmware's web UI, or
using the `vendor's "debrick" process
<https://docs.gl-inet.com/router/en/3/tutorials/debrick/>`_. The last
of these options has a lot to recommend it for a first attempt:

* it works no matter what firmware is currently installed

* it doesn't require plugging a router into the same network as your
  build system and potentially messing up your actual upstream

* no need to open the device and add cables

You can read detailed instructions on the vendor site, but the short version is:

1. turn the device off
2. connect it by ethernet cable to a computer
3. configure the computer to have static ip address 192.168.1.10
4. while holding down the Reset button, turn the device on
5. after about five seconds you can release the Reset button
6. visit http://192.168.1.1/ using a web browser on the connected computer
7. click on "Browse" and choose :file:`result/firmware.bin`
8. click on "Update firmware"
9. wait a minute or so while it updates.

There's no feedback from the web interface when the flashing is
finished, but what should happen is that the router reboots and
starts running Liminix. Now you need to figure out what address it got
from DHCP - e.g. by checking the DHCP server logs, or maybe by pinging
``hello.lan`` or something. Once you've found it on the
network you can ping it and ssh to it just like you did the Qemu
example, but this time for real.

.. warning:: Do not leave the default root password in place on any
             device exposed to the internet!  Although it has no
             writable storage and no default route, a motivated attacker
	     with some imagination could probably still do something
	     awful using it.

Congratulations Part II! You have installed your first Liminix system on
actual hardware - albeit that it *still* has no practical use.

Exercise for the reader: change the default password by editing
:file:`examples/hello-from-mt300.nix`, and then create and upload a
new image that has it set to something less hopeless.

Routing
*******

The third example :file:`examples/demo.nix` is a fully-functional home
"WiFi router" - although you will have to edit it a bit before it will
actually work for you. Copy :file:`examples/demo.nix` to
:file:`my-router.nix` (or other name of your choice) and open it in
your favourite text editor. Everywhere that the text :code:`EDIT`
appears is either a place you probably want to change or a place you
almost certainly need to change.

There's a lot going on in this configuration:

* it provides a wireless access point using the :code:`hostapd`
  service: in this stanza you can change the ssid, the channel,
  the passphrase etc.

* the wireless lan and wired lan are bridged together with the
  :code:`bridge` service, so that your wired and wireless clients appear
  to be on the same network.

.. tip:: If you were using a hardware device that provides both 2.4GHz
	  and 5GHz wifi, you'd probably find that it has two wireless
	  devices (often called wlan0 and wlan1). In Liminix we handle
	  this by running two :code:`hostapd` services, and adding
	  both of them to the network bridge along with the wired lan.
	  (You can see an example in :file:`examples/rotuer.nix`)

* we use the combination DNS and DHCP daemon provided by the
  :code:`dnsmasq` service, which you can configure

* the upstream network is "PPP over Ethernet", provided by the
  :code:`pppoe` service. Assuming that your ISP uses this standard,
  they will have provided you with a PPP username and password
  (sometimes this will be listed as "PAP" or "CHAP") which you can edit
  into the configuration

* this example supports the new [#ipv6]_ Internet Protocol v6
  as well as traditional IPv4. Configuring IPv6 seems to
  vary from one ISP to the next: this example expects them
  to be providing IP address allocation and "prefix delegation"
  using DHCP6.

Build it using the same method as the previous example


.. code-block:: console

    nix-build -I liminix-config=./my-router.nix \
     --arg device "import ./devices/gl-mt300a" -A outputs.default

and then you can flash it to the device.


Bonus: in-place updates
=======================

This configuration uses a writable filesystem (see the line
:code:`rootfsType = "jffs2"`), which means that once you've flashed it
for the first time, you can make further updates over SSH onto the
running router. To try this, make a small change (I'd suggest changing
the hostname) and then run

.. code-block:: console

    nix-shell --run "liminix-rebuild root@address-of-the-device  -I liminix-config=./my-router.nix --arg device "import ./devices/gl-ar750""

(This requires the device to be network-accessible from your build
machine, which for a test/demo system might involve a second network
device in your build system - USB ethernet adapters are cheap - or
a bit of messing around unplugging cables.)


Final thoughts
**************

* These are demonstration configs for pedagogical purposes. If you'd
  like to see some more realistic uses of Liminix,
  :file:`examples/rotuer,arhcive,extneder.nix` are based on some
  actual real hosts in my home network.

* These example images are not writable. Later we will explain how to
  generate an image that can be changed after installation, and
  even use :command:`liminix-rebuild` (analogous to :command:`nixos-rebuild`)
  to keep it up to date.

* The technique used here for flashing was chosen mostly because it
  doesn't need much infrastructure/tooling, but it is a bit of a faff
  (requires physical access, vendor specific). There are slicker ways
  to do it that need a bit more setup - we'll talk about that later as
  well.



.. rubric:: Footnotes

.. [#ipv6] `RFC1883 Internet Protocol, Version 6 <https://datatracker.ietf.org/doc/html/rfc1883>`_ was published in 1995, so only "new" when Bill Clinton was US President
