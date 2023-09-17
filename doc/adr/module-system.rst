Module system
#############

**Status:** Adopted; implemented in July-September 2023


Context
*******

Liminix users need a way to assemble a full system configuration by
combining smaller, more isolated and reusable components, otherwise
systems will be unwieldy and copy-and-paste will be rife.


Alternatives
************

NixOS module system
===================

The NixOS module system addresses many of these concerns. A module is
a Nix function which accepts a ``configuration`` attrset and some
other parameters, and returns a new fragment of ``configuration``
which is merged into it. It includes a DSL describing the permitted
types of values for each key in the configuration, which is used for
checking that the supplied parameters are valid and also governs what
to do if two modules both specify a value for the same key. (Usually
they are "merged", using some type-appropriate concept of merging.)

Usually a NixOS module looks only (or mostly only) at a particular
subtree of the overall configuration which is hardcoded in the module
definition, but the configuration fragment it returns may touch any
part of the schema. For example, the factorio module refers to
``config.services.factorio``, and it returns values for keys in
``systemd.services.factorio`` and ``networking.firewall``. There is no
way to use this module to run **two** factorio services with different
config (e.g. on different ports) - the only way to make that
possible would be to extend the module definition so that it
accepts a collection of game configurations and then create
a systemd service for each.


NixWRT module system
====================

NixWRT, the (now defunct) predecessor of Liminix, used a homegrown
module system modelled on the Nixpkgs overlay pattern.  Each module is
a function that accepts  ``super`` and ``self`` parameters, and
using <handwaves>that fixpoint magic thing</handwaves>
is called in a chain with the configuration returned by the previous
module and the final configuration.

NixWRT modules mostly don't refer to the configuration object to
decide how to configure themselves, but accept their parameters
directly as function parameters. For example, the configuration
file for "arhcive" (a backup server) includes this text:

.. code-block:: nix

   (sshd {
     hostkey = secrets.sshHostKey;
     authkeys = { root = lib.splitString "\n" secrets.myKeys; };
   })
   busybox
   (usbdisk {
     label = "backup-disk";
     mountpoint = "/srv";
     fstype = "ext4";
     options = "rw";
   })

This gives us flexibility that NixOS modules don't: for example, if we
want to mount two USB disks, we can simply repeat that module twice
with different parameters - and the module definition doesn't have to
handle it specially.

However, the downside of this system is that we didn't implement any
concept of "types" - there is no type information, so there is no
systematic checking that parameters are valid, and if two modules set
the same config key then the rules for merging are entirely ad hoc.

There is a further (arguable) downside, which is that the
configuration is not just data - it's now part code. While it could be
feasible (though I've never seen it done) to encode a NixOS
configuration using Yaml or XML and then manipulate it as data, this
is not even possible using the NixWRT system.


Use services for everything
===========================

The most common properties that a Liminix configuration needs to
define are:

* which services (processes) to run
* what packages to install
* permitted users and groups
* Linux kernel configuration options
* Busybox applets
* filesystem layout

Suppose we only had services?

A Liminix service is (also) a derivation, so it is able to
create any files it likes inside its own store path, and
transitively require other packages simply by referring to them.
If it needs particular kernel options it could define them
as kernel modules to be loaded on demand when the service
starts (see the nftables module for an example). However:

* there is no way for a service to add busybox modules

* it cannot create files outside of its store path, so
  wouldn't be able to make e.g. :file:`/etc/something.conf`

* no way to create users/groups. We could steal the DynamicUsers idea
  from systemd and make them on demand, but this starts to get a bit
  more complicated.

These limitations force us to reject this option as a general
solution - though we should strive *where possible* to implement
functionality as services and to minimise the proportion of Liminix
that manipulates the global configuration.


Decision
********

"Why not both?"  None of these options is sufficient alone, so we are
going to do a mixture.

We will use the NixOS module system, but instead of expecting modules
to create systemd services as instances, they will expose "service
templates": functions that accept an attrset and return an
appropriately configured service that can be assigned by the caller
to a key in ``config.services``.

We will typecheck the service template function parameters using the
same type-checking code as NixOS uses for its modules.

An example may make this clearer: to add an NTP
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
have to create the actual service using the template.



Consequences
************

This decision has both good and bad consequences

Pro
===

* We have a workable system for reusing configuration elements in
  Liminix.

* We have type checking for most imortant things, reducing the risk of
  deploying an invalid configuration.

* We have a simple mechanism for creating multiple services based on
  the same module, without buulding that logic into the module
  definition itself. For example, we could create two SSH daemons on
  different ports, or DHCP clients with different configurations on
  different network devices.

* We expect to be able to automate the generation of module
  documentation.

Con
===


* By departing somewhat from the NixOS conventions we increase the
  amount of code we have to write/maintain ourselves - and the
  learning burden on users who are already familiar with that system.

* Liminix configurations contain function calls and aren't just data,
  which means we can ony realistically interpret or introspect
  them with the Nix interpreter itself - we can't query them
  as data with other non-Nix tools.
