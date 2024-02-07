let
  drop = expr : "${expr} drop";
  accept = expr : "${expr} accept";
  mcast-scope = 8;
  allow-incoming = false;
in {
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

      # I think this means "check FIB for (saddr, iif) to see if we
      # could route a packet to that address using that interface",
      # and if we can't then it was an inapproppriate source address
      # for packets received _from_ said interface
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
      (drop "ip6 saddr ::FFFF:0:0/96")# IPv4-mapped addresses
      (drop "ip6 daddr ::FFFF:0:0/96")
      (drop "ip6 saddr fe80::/10") # link-local unicast
      (drop "ip6 daddr fe80::/10")
      (drop "ip6 saddr fc00::/7") # unique-local addresses
      (drop "ip6 daddr fc00::/7")
      (drop "ip6 saddr 2001:10::/28") # ORCHID [RFC4843].
      (drop "ip6 daddr 2001:10::/28")

      (drop "ip6 saddr fc00::/7") # unique local source
      (drop "ip6 daddr fc00::/7") # and/or dst addresses [RFC4193]

      # multicast with wrong scopes
      (drop
        # dest addr first byte 0xff, low nibble of second byte <= scope
        # https://www.mankier.com/8/nft#Payload_Expressions-Raw_Payload_Expression
        "@nh,192,8 eq 0xff @nh,204,4 le ${toString mcast-scope}")

      (accept "oifname \"int\" iifname \"ppp0\" meta l4proto udp ct state established,related")
      (accept "iifname \"int\" oifname \"ppp0\" meta l4proto udp")

      (accept "meta l4proto icmpv6")
      (accept "meta l4proto ah")
      (accept "meta l4proto esp")

      # does this ever get used or does the preceding general udp accept
      # already grab anything that might get here?
      (accept "oifname \"ppp0\" udp dport 500") # IKE Protocol [RFC5996]. haha zyxel
      (accept "ip6 nexthdr 139") #  Host Identity Protocol

      ## FIXME no support yet for recs 27-30 Mobility Header

      (accept "oifname \"int\" iifname \"ppp0\" meta l4proto tcp ct state established,related")
      (accept "iifname \"int\" oifname \"ppp0\" meta l4proto tcp")

      (accept "oifname \"int\" iifname \"ppp0\" meta l4proto sctp ct state established,related")
      (accept "iifname \"int\" oifname \"ppp0\" meta l4proto sctp")

      (accept "oifname \"int\" iifname \"ppp0\" meta l4proto dccp ct state established,related")
      (accept "iifname \"int\" oifname \"ppp0\" meta l4proto dccp")

      # we can allow all reasonable inbound, or we can use an explicit
      # allowlist to enumerate the endpoints that are allowed to
      # accept inbound from the WAN
      (if allow-incoming
       then accept "oifname \"int\" iifname \"ppp0\""
       else "oifname \"int\" iifname \"ppp0\" jump incoming-allowed-ip6"
      )
      # allow all outbound and any inbound that's part of a
      # recognised (outbound-initiated) flow
      (accept "oifname \"int\" iifname \"ppp0\" ct state established,related")
      (accept "iifname \"int\" oifname \"ppp0\" ")

      "log prefix \"denied forward-ip6 \""
    ];
  };

  input-ip6-lan = {
    type = "filter";
    family = "ip6";

    rules = [
      (accept "udp dport 547") # dhcp, could restrict to daddr ff02::1:2
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
      "iifname int jump input-ip6-lan"
      "iifname ppp0 jump input-ip6-wan"
      (if allow-incoming
       then accept "oifname \"int\" iifname \"ppp0\""
       else "oifname \"int\" iifname \"ppp0\" jump incoming-allowed-ip6"
      )
      # how does this even make sense in an input chain?
      (accept "oifname \"int\" iifname \"ppp0\"  ct state established,related")
      (accept "iifname \"int\" oifname \"ppp0\" ")
      "log prefix \"denied input-ip6 \""
    ];
  };

  incoming-allowed-ip6 = {
    type = "filter";
    family = "ip6";
    rules = [
      # this is where you put permitted incoming connections
      # "oifname \"int\" ip6 daddr 2001:8b0:de3a:40de::e9d tcp dport 22"
    ];
  };

  nat-tx = {
    type = "nat";
    hook = "postrouting";
    priority = "100";
    policy = "accept";
    family = "ip";
    rules = [
      "oifname \"ppp0\" masquerade"
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

  input-ip4-lan = {
    type = "filter";
    family = "ip";

    rules = [
      (accept "udp dport 547")
      (accept "tcp dport 22")
    ];
  };

  input-ip4-wan = {
    type = "filter";
    family = "ip";

    rules = [
    ];
  };

  input-ip4 = {
    type = "filter";
    family = "ip";
    policy = "drop";
    hook = "input";
    rules = [
      "iifname lo accept"
      "ct state vmap { established : accept, related : accept, invalid : drop }"
      "iifname int jump input-ip4-lan"
      "iifname ppp0 jump input-ip4-wan"
      "oifname \"int\" iifname \"ppp0\" jump incoming-allowed-ip4"
      "log prefix \"denied input-ip4 \""
    ];
  };

  forward-ip4 = {
    type = "filter";
    family = "ip";
    policy = "drop";
    hook = "forward";
    rules = [
      "iifname \"int\" accept"
      "ct state vmap { established : accept, related : accept, invalid : drop }"
      "oifname \"int\" iifname \"ppp0\" jump incoming-allowed-ip4"
      "log prefix \"denied forward-ip4 \""
    ];
  };

  incoming-allowed-ip4 = {
    type = "filter";
    family = "ip";
    rules = [
      # this is where you put permitted incoming
      # connections. Practically there's not a lot of use for this
      # chain unless you have routable ipv4 addresses
    ];
  };

}
