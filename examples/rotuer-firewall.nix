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
    ];
  };
  input-lan = {
    type = "filter";
    family = "ip6";

    rules = [
      (accept "udp dport 547") # dhcp, could restrict to daddr ff02::1:2
      (accept "tcp dport 22")
    ];
  };
  input-ip6 = {
    type = "filter";
    family = "ip6";
    policy = "drop";
    hook = "input";
    rules = [
      (accept "meta l4proto icmpv6")
      "iifname int jump input-lan"
      (if allow-incoming
       then accept "oifname \"int\" iifname \"ppp0\""
       else "oifname \"int\" iifname \"ppp0\" jump incoming-allowed-ip6"
      )
      # how does this even make sense in an input chain?
      (accept "oifname \"int\" iifname \"ppp0\"  ct state established,related")
      (accept "iifname \"int\" oifname \"ppp0\" ")
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
}
