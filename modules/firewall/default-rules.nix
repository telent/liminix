let
  drop = expr: "${expr} drop";
  accept = expr: "${expr} accept";
  mcast-scope = 8;
  allow-incoming = false;
in
{
  bogons-ip6 = {
    type = "filter";
    family = "ip6";
    policy = "accept";
    hook = "prerouting";
    rules = [
      (drop "ip6 saddr ff00::/8") # multicast saddr is illegal

      (drop "ip6 saddr ::/128") # unspecified address
      (drop "ip6 daddr ::/128")
      (drop "ip6 saddr 2001:db8::/32") # documentation addresses
      (drop "ip6 daddr 2001:db8::/32")

      # Reverse path filtering: drop packet if it's not coming from
      # the same interface that we'd use to send a reply.  Works by
      # doing a lookup in the FIB to find how we'd route a packet _to_
      # saddr through iif, and then checking the output interface
      # returned by the lookup. if oif is 0, that means no route was
      # found for that address with that interface, so the packet can
      # be dropped
      #
      #  https://wiki.nftables.org/wiki-nftables/index.php/Matching_routing_information#fib
      #  https://thr3ads.net/netfilter-buglog/2018/01/2843000-Bug-1220-New-Reverse-path-filtering-using-fib-needs-better-documentation
      (drop "fib saddr . iif oif eq 0")

      (drop "icmpv6 type router-renumbering")
      (drop "icmpv6 type 139") # Node Information Query
      (drop "icmpv6 type 140") # Node Information Response
      (drop "icmpv6 type 100")
      (drop "icmpv6 type 101")
      (drop "icmpv6 type 200")
      (drop "icmpv6 type 201")
      (drop "icmpv6 type 127")
      (drop "icmpv6 type 255")
      (drop "icmpv6 type destination-unreachable ct state invalid,untracked")
    ];
  };

  forward-ip6 = {
    type = "filter";
    family = "ip6";
    policy = "drop";
    hook = "forward";
    rules = [
      (drop "ip6 saddr ::1/128") # loopback address [RFC4291]
      (drop "ip6 daddr ::1/128")
      (drop "ip6 saddr ::FFFF:0:0/96") # IPv4-mapped addresses
      (drop "ip6 daddr ::FFFF:0:0/96")
      (drop "ip6 saddr fe80::/10") # link-local unicast
      (drop "ip6 daddr fe80::/10")
      (drop "ip6 saddr 2001:10::/28") # ORCHID [RFC4843].
      (drop "ip6 daddr 2001:10::/28")

      (drop "ip6 saddr fc00::/7") # unique local source
      (drop "ip6 daddr fc00::/7") # and/or dst addresses [RFC4193]

      # multicast with wrong scopes
      (drop
        # dest addr first byte 0xff, low nibble of second byte <= scope
        # https://www.mankier.com/8/nft#Payload_Expressions-Raw_Payload_Expression
        "@nh,192,8 eq 0xff @nh,204,4 le ${toString mcast-scope}"
      )

      (accept "oifname @lan iifname @wan meta l4proto udp ct state established,related")
      (accept "iifname @lan oifname @wan meta l4proto udp")

      (accept "meta l4proto icmpv6")
      (accept "meta l4proto ah")
      (accept "meta l4proto esp")

      # does this ever get used or does the preceding general udp accept
      # already grab anything that might get here?
      (accept "oifname @wan udp dport 500") # IKE Protocol [RFC5996]. haha zyxel
      (accept "ip6 nexthdr 139") # Host Identity Protocol

      ## FIXME no support yet for recs 27-30 Mobility Header

      (accept "oifname @lan iifname @wan meta l4proto tcp ct state established,related")
      (accept "iifname @lan oifname @wan meta l4proto tcp")

      (accept "oifname @lan iifname @wan meta l4proto sctp ct state established,related")
      (accept "iifname @lan oifname @wan meta l4proto sctp")

      (accept "oifname @lan iifname @wan meta l4proto dccp ct state established,related")
      (accept "iifname @lan oifname @wan meta l4proto dccp")

      # we can allow all reasonable inbound, or we can use an explicit
      # allowlist to enumerate the endpoints that are allowed to
      # accept inbound from the WAN
      (
        if allow-incoming then
          accept "oifname @lan iifname @wan"
        else
          "iifname @wan jump incoming-allowed-ip6"
      )
      # allow all outbound and any inbound that's part of a
      # recognised (outbound-initiated) flow
      (accept "oifname @lan iifname @wan ct state established,related")
      (accept "iifname @lan oifname @wan ")

      "log prefix \"DENIED CHAIN=forward-ip6 \""
    ];
  };

  input-ip6-lan = {
    type = "filter";
    family = "ip6";

    rules = [
      (accept "udp dport 547") # dhcp, could restrict to daddr ff02::1:2
      (accept "udp dport 53") # dns
      (accept "tcp dport 22")
    ];
  };

  input-ip6-wan = {
    type = "filter";
    family = "ip6";

    rules = [
      (accept "udp dport 546") # dhcp client, needed for prefix delegation
    ];
  };

  input-ip6 = {
    type = "filter";
    family = "ip6";
    policy = "drop";
    hook = "input";
    rules = [
      (accept "meta l4proto icmpv6")
      "iifname @lan jump input-ip6-lan"
      "iifname @wan jump input-ip6-wan"
      (if allow-incoming then accept "iifname @wan" else "iifname @wan jump incoming-allowed-ip6")
      # how does this even make sense in an input chain?
      (accept "iifname @wan  ct state established,related")
      (accept "iifname @lan ")
      "log prefix \"DENIED CHAIN=input-ip6 \""
    ];
  };

  incoming-allowed-ip6 = {
    type = "filter";
    family = "ip6";
    rules = [
      # this is where you put permitted incoming connections
      # "oifname @lan ip6 daddr 2001:8b0:de3a:40de::e9d tcp dport 22"
    ];
  };

  nat-tx = {
    type = "nat";
    hook = "postrouting";
    priority = "100";
    policy = "accept";
    family = "ip";
    rules = [
      "oifname @wan masquerade"
    ];
  };

  nat-rx = {
    type = "nat";
    hook = "prerouting";
    priority = "-100";
    family = "ip";
    policy = "accept";
    rules = [
      # per https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sec-configuring_nat_using_nftables:
      # "Even if you do not add a rule to the prerouting chain, the
      # nftables framework requires this chain to match incoming
      # packet replies. "
    ];
  };

  # these chains are for rules that have to be present for things to
  # basically work at all: for example, the router won't issue DHCP
  # unless it's allowed to receive DHCP requests. For "site policy"
  # rules you may prefer to use incoming-allowed-ip[46] instead

  input-ip4-lan = {
    type = "filter";
    family = "ip";

    rules = [
      (accept "udp dport 67") # dhcp
      (accept "udp dport 53") # dns
      (accept "tcp dport 22") # ssh
    ];
  };

  input-ip4-wan = {
    type = "filter";
    family = "ip";

    rules = [ ];
  };

  input-ip4 = {
    type = "filter";
    family = "ip";
    policy = "drop";
    hook = "input";
    rules = [
      "iifname lo accept"
      "icmp type { echo-request, echo-reply } accept"
      "iifname @lan jump input-ip4-lan"
      "iifname @wan jump input-ip4-wan"
      "iifname @wan jump incoming-allowed-ip4"
      "ct state established,related accept"
      "log prefix \"DENIED CHAIN=input-ip4 \""
    ];
  };

  forward-ip4 = {
    type = "filter";
    family = "ip";
    policy = "drop";
    hook = "forward";
    rules = [
      "iifname @lan accept"
      "ct state established,related accept"
      "oifname @lan iifname @wan jump incoming-allowed-ip4"
      "log prefix \"DENIED CHAIN=forward-ip4 \""
    ];
  };

  incoming-allowed-ip4 = {
    type = "filter";
    family = "ip";
    rules = [
      # This is where you put permitted incoming connections. If
      # you're using NAT and want to forward a port from outside to
      # devices on the LAN, then you need a DNAT rule in nat-rx chain
      # *and* to accept the packet in this chain (specifying the
      # internal (RFC1918) address).
    ];
  };

}
