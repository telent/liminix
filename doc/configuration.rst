.. _configuration:

Configuration
#############

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

.. _configuration-services:

Services
********

In Liminix a service is any kind of long-running task or process on
the system, that is managed (started, stopped, and monitored) by a
service supervisor.  A typical SOHO router might have services to

* answer DHCP and DNS requests from the LAN
* provide a wireless access point
* connect using PPPoE or L2TP to an upstream network
* start/stop the firewall
* enable/disable IP packet forwarding
* mount filesystems

(Some of these might not be considered services using other
definitions of the term: for example, this L2TP process would be a
"client" in the client/server classification; and enabling packet
forwarding doesn't require any long-lived process - just a setting to
be toggled.  However, there is value in being able to use the same
abstractions for all the things to manage them and specify their
dependency relationships - so in Liminix "everything is a service")

The service supervision system enables service health monitoring,
restart of unhealthy services, and failover to "backup" services when
a primary service fails or its dependencies are unavailable. The
intention is that you have a framework in which you can specify policy
requirements like "ethernet wan dhcp-client should be restarted if it
crashes, but if it can't start because the hardware link is down, then
4G ppp service should be started instead".

Any attribute in `config.services` will become part of the default set
of services that s6-rc will try to bring up.  Services are usually
started at boot time, but **controlled services** are those that are
required only in particular contexts.  For example, a service to mount
a USB backup drive should run only when the drive is attached to the
system. Liminix currently implements three kinds of controlled service:

* "uevent-rule" service controllers use sysfs/uevent to identify when
  particular hardware devices are present, and start/stop a controlled
  service appropriately.

* the "round-robin" service controller is used for service failover:
  it allows you to specify a list of services and runs each of them
  in turn until it exits, then runs the next.

* the "health-check" service wraps another service, and runs a "health
  check" command at regular intervals. When the health check fails,
  indicating that the wrapped service is not working, it is terminated
  and allowed to restart.


Writing services
================

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

Modules in Liminix conventionally live in
:file:`modules/somename/default.nix`. If you want or need to
write your own, you may wish to refer to the
examples there in conjunction with reading this section.

A module is a function that accepts ``{lib, pkgs, config, ... }`` and
returns an attrset with keys ``imports, options config``.

* ``imports`` is a list of paths to the other modules required by this one

* ``options`` is a nested set of option declarations

* ``config`` is a nested set of option definitions

The NixOS manual section `Writing NixOS Modules
<https://nixos.org/manual/nixos/stable/#sec-writing-modules>`_ is a
quite comprehensive reference to writing NixOS modules, which is also
mostly applicable to Liminix except that it doesn't cover
service templates.

Service templates
=================

To expose a service template in a module, it needs the following:

* an option declaration for ``system.service.myservicename`` with the
  type of ``liminix.lib.types.serviceDefn``

.. code-block:: nix

    options = {
      system.service.cowsay = mkOption {
	type = liminix.lib.types.serviceDefn;
      };
    };

* an option definition for the same key, which specifies where to
  import the service template from (often :file:`./service.nix`)
  and the types of its parameters.

.. code-block:: nix

    config.system.service.cowsay = config.system.callService ./service.nix {
      address = mkOption {
	type = types.str;
	default = "0.0.0.0";
	description = "Listen on specified address";
	example = "127.0.0.1";
      };
      port = mkOption {
	type = types.port;
	default = 22;
	description = "Listen on specified TCP port";
      };
      breed = mkOption {
	type = types.str;
	default = "British Friesian"
	description = "Breed of the cow";
      };
    };

Then you need to provide the service template itself, probably in
:file:`./service.nix`:

.. code-block:: nix

    {
      # any nixpkgs package can be named here
      liminix
    , cowsayd
    , serviceFns
    , lib
    }:
    # these are the parameters declared in the callService invocation
    { address, port, breed} :
    let
      inherit (liminix.services) longrun;
      inherit (lib.strings) escapeShellArg;
    in longrun {
      name = "cowsayd";
      run = "${cowsayd}/bin/cowsayd --address ${address} --port ${builtins.toString port} --breed ${escapeShellArg breed}";
    }

.. tip::

   Not relevant to module-based services specifically, but a common
   gotcha when specifiying services is forgetting to transform "rich"
   parameter values into text when composing a command for the shell
   to execute. Note here that the port number, an integer, is
   stringified with ``toString``, and the name of the breed,
   which may contain spaces, is
   escaped with ``escapeShellArg``

Types
=====

All of the NixOS module types are available in Liminix. These
Liminix-specific types also exist in ``pkgs.liminix.lib.types``:

* ``service``: an s6-rc service
* ``interface``: an s6-rc service which specifies a network
  interface
* ``serviceDefn``: a service "template" definition

In the future it is likely that we will extend this to include other
useful types in the networking domain: for example; IP address,
network prefix or netmask, protocol family and others as we find them.
