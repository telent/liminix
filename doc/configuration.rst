Configuration and Module Guide
##############################

Liminix uses the Nix language to provide congruent configuration
management.  This means that to change anything about the way in
which a Liminix system works, you make that change in
your :file:`configuration.nix` (or one of the other files it references),
and rerun :command:`nix-build` or :command:`liminix-rebuild` to action
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


Configuration taxonomy
**********************

There are many things you can specify in a configuration, but these
are the ones you most commonly need to change:

* which services (processes) to run
* what packages to install
* permitted users and groups
* Linux kernel configuration options
* Busybox applets
* filesystem layout


Modules
*******

**Modules** are a means of abstraction which allow "bundling"
of configuration options related to a common purpose or theme. For
example, the ``dnsmasq`` module defines a template for a dnsmasq
service, ensures that the dnsmasq package is installed, and provides a
dnsmasq user and group for the service to run as. The ``ppp`` module
defines a service template and also enables various PPP-related kernel
configuration.

Not all modules are included in the configuration by default, because
that would mean that the kernel (and the Busybox binary providing
common CLI tools) was compiled with many unnecessary bells and whistles
and therefore be bigger than needed. (This is not purely an academic concern
if your device has little flash storage).  Therefore, specifying a
service is usually a two-step process.  For example, to add an NTP
service you first add :file:`modules/ntp` to your ``imports`` list,
then you create a service by calling
:code:`config.system.service.ntp.build { .... }` with the appropriate
service-dependent configuration parameters.

.. code-block:: nix

  let svc = config.system.service;
  in {
    # ...
    imports = [
      ./modules/ntp
      # ....
    ];
    config.services.ntp = svc.ntp.build {
      pools = { "pool.ntp.org" = ["iburst"]; };
      makestep = { threshold = 1.0; limit = 3; };
    };

Merely including the module won't define the service on its own: it
only creates the template in ``config.system.service.foo`` and you
have to create an actual service using the template. This is an
intentional choice to allow the creation of multiple
differently-configured services based on the same template - perhaps
e.g. when you have multiple networks (VPNs etc) in different trust
domains, or you want to run two SSH daemons on different ports.
(For the background to this, please refer to the :doc:`architecture decision record <adr/module-system>`)

.. tip:: Liminix modules should be quite familiar (but also different)
	 if you already know how to use NixOS modules. We use the
	 NixOS module infrastructure code, meaning that you should
	 recognise the syntax, the type system, the rules for
	 combining configuration values from different sources. We
	 don't use the NixOS modules themselves, because the
	 underlying system is not similar enough for them to work.


Services
********

We use the `s6-rc service manager <https://www.skarnet.org/software/s6-rc/overview.html>`_  to start/stop/restart services and handle
service dependencies. Any attribute in `config.services` will become
part of the default set of services that s6-rc will try to bring up on
boot.

For the most part, for common use cases, hopefully the services you
need will be defined by modules and you will only have to pass the
right parameters to ``build``.

Should you need to create a custom service of your own devising, use
the `oneshot` or `longrun` functions:

* a "longrun" service is the "normal" service concept: it has a
  ``run`` action which describes the process to start, and it watches
  that process to restart it if it exits. The process should not
  attempt to daemonize or "background" itself, otherwise s6-rc will think
  it died. Whatever it prints to standard output/standard error
  will be logged.

.. code-block:: nix

    config.services.cowsayd = pkgs.liminix.services.longrun {
      name = "cowsayd";
      run = "${pkgs.cowsayd}/bin/cowsayd --port 3001 --breed hereford";
      # don't start this until the lan interface is ready
      dependencies = [ config.services.lan ];
    }


* a "oneshot" service doesn't have a process attached. It consists of
  ``up`` and ``down`` actions which are bits of shell script that
  are run at the appropriate points in the service lifecycle

.. code-block:: nix

    config.services.greenled = pkgs.liminix.services.oneshot {
      name = "greenled";
      up = ''
	echo 17 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio17/direction
	echo 0   > /sys/class/gpio/gpio17/value
      '';
      down = ''
	echo 0   > /sys/class/gpio/gpio17/value
      '';
    }

Services may have dependencies: as you see above in the ``cowsayd``
example, it depends on some service called ``config.services.lan``,
meaning that it won't be started until that other service is up.

..
	TODO: explain service outputs

..
	TODO: outputs that change, and services that poll other services

Module implementation
*********************

..
	TODO: make your own modules

	* how a module exposes services
	* defining types
