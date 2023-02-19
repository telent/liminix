The Future
##########

What about NixWRT?

This is an in-progress rewrite of NixWRT, incorporating Lessons
Learned. That said, as of today it is not yet at feature parity.

Liminix will eventually provide these differentiators over NixWRT:

* a writable filesystem so that software updates or reconfiguration
  (e.g. changing passwords) don't require taking the device offline to
  reflash it.

* more flexible service management with dependencies, to allow
  configurations such as "route through PPPoE if it is healthy, with
  fallback to LTE"

* a spec for valid configuration options (a la NixOS module options)
  to that we can detect errors at evaluation time instead of producing
  a bad image.

* a network-based mechanism for secrets management so that changes can
  be pushed from a central location to several Liminix devices at once

* send device metrics and logs to a monitoring/alerting/o11y
  infrastructure

Today though, it does approximately none of these things and certainly
not on real hardware.


Articles of interest
####################

* `Build Safety of Software in 28 Popular Home Routers <https://cyber-itl.org/assets/papers/2018/build_safety_of_software_in_28_popular_home_routers.pdf>`_: "of the access
   points and routers we reviewed, not a single one took full
   advantage of the basic application armoring features provided by
   the operating system. Indeed, only one or two models even came
   close, and no brand did well consistently across all models tested"

* `A PPPoE Implementation for Linux <https://static.usenix.org/publications/library/proceedings/als00/2000papers/papers/full_papers/skoll/skoll_html/index.html>`_:
  "Many DSL service providers use PPPoE for residential broadband
  Internet access. This paper briefly describes the PPPoE protocol,
  presents strategies for implementing it under Linux and describes in
  detail a user-space implementation of a PPPoE client."

* `PPP IPV6CP vs DHCPv6 at AAISP <https://www.revk.uk/2011/01/ppp-ipv6cp-vs-dhcpv6.html>`_

