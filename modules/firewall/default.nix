## Firewall
## ========
##
## Provides a service to create an nftables ruleset based on
## configuration supplied to it.

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
  inherit (pkgs.liminix.services) oneshot;

  kconf = isModule :
    # setting isModule false is utterly untested and mostly
    # unimplemented: I say this to preempt any "how on earth is this
    # even supposed to work?" questions
    let yes = if isModule then "m" else "y";
    in {
      NETFILTER = "y";
      NETFILTER_ADVANCED = "y";
      NETFILTER_NETLINK = yes;
      NF_CONNTRACK = yes;

      IP6_NF_IPTABLES=  yes;
      IP_NF_IPTABLES = yes;
      IP_NF_NAT = yes;
      IP_NF_TARGET_MASQUERADE = yes;

      NFT_CT = yes;
      NFT_FIB_IPV4 = yes;
      NFT_FIB_IPV6 = yes;
      NFT_LOG = yes;
      NFT_MASQ = yes;
      NFT_NAT = yes;
      NFT_REJECT = yes;
      NFT_REJECT_INET = yes;

      NF_CT_PROTO_DCCP = "y";
      NF_CT_PROTO_SCTP = "y";
      NF_CT_PROTO_UDPLITE = "y";
      NF_LOG_SYSLOG = yes;
      NF_NAT = yes;
      NF_NAT_MASQUERADE = "y";
      NF_TABLES = yes;
      NF_TABLES_INET = "y";
      NF_TABLES_IPV4 = "y";
      NF_TABLES_IPV6 = "y";
    };
  kmodules = pkgs.kernel-modules.override {
    kernelSrc = config.system.outputs.kernel.src;
    modulesupport = config.system.outputs.kernel.modulesupport;
    targets = [
      "nft_fib_ipv4"
      "nft_fib_ipv6"
      "nf_log_syslog"

      "ip6_tables"
      "ip_tables"
      "iptable_nat"
      "nf_conntrack"
      "nf_defrag_ipv4"
      "nf_defrag_ipv6"
      "nf_log_syslog"
      "nf_nat"
      "nf_reject_ipv4"
      "nf_reject_ipv6"
      "nf_tables"
      "nft_chain_nat"
      "nft_ct"
      "nft_fib"
      "nft_fib_ipv4"
      "nft_fib_ipv6"
      "nft_log"
      "nft_masq"
      "nft_nat"
      "nft_reject"
      "nft_reject_inet"
      "nft_reject_ipv4"
      "nft_reject_ipv6"
      "x_tables"
      "xt_MASQUERADE"
      "xt_nat"
      "xt_tcpudp"
    ];
    kconfig = kconf true;
  };
  loadModules = oneshot {
    name = "firewall-modules";
    up = "sh ${kmodules}/load.sh";
    down = "sh ${kmodules}/unload.sh";
  };
in
{
  options = {
    system.service.firewall = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    system.service.firewall =
      let svc = liminix.callService ./service.nix  {
            ruleset = mkOption {
              type = types.attrsOf types.attrs;   # we could usefully tighten this a bit :-)
              description = "firewall ruleset";
            };
          };
      in svc // {
        build = args :
          let args' = args // {
                dependencies = (args.dependencies or []) ++ [loadModules];
              };
          in svc.build args' ;
      };

    kernel.config = kconf true;
  };
}
