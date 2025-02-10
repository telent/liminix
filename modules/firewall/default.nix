## Firewall
## ========
##
## Provides a service to create an nftables ruleset based on
## configuration supplied to it.

{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;

  kmodules = pkgs.kmodloader.override {
    inherit (config.system.outputs) kernel;
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
      let
        svc = config.system.callService ./service.nix {
          extraRules = mkOption {
            type = types.attrsOf types.attrs;
            description = "firewall ruleset";
            default = { };
          };
          zones = mkOption {
            type = types.attrsOf (types.listOf liminix.lib.types.service);
            default = { };
            example = lib.literalExpression ''
              {
                lan = with config.hardware.networkInterfaces; [ int ];
                wan = [ config.services.ppp0 ];
              }
            '';
          };
          rules = mkOption {
            type = types.attrsOf types.attrs; # we could usefully tighten this a bit :-)
            default = import ./default-rules.nix;
            description = "firewall ruleset";
          };
        };
      in
      svc
      // {
        build =
          args:
          let
            args' = args // {
              dependencies = (args.dependencies or [ ]) ++ [ kmodules ];
            };
          in
          svc.build args';
      };
    programs.busybox.applets = [
      "insmod"
      "rmmod"
    ];
    kernel.config = {
      NETFILTER = "y";
      NETFILTER_ADVANCED = "y";
      NETFILTER_NETLINK = "m";
      NF_CONNTRACK = "m";

      NETLINK_DIAG = "y";

      IP6_NF_IPTABLES = "m";
      IP_NF_IPTABLES = "m";
      IP_NF_NAT = "m";
      IP_NF_TARGET_MASQUERADE = "m";

      NFT_CT = "m";
      NFT_FIB_IPV4 = "m";
      NFT_FIB_IPV6 = "m";
      NFT_LOG = "m";
      NFT_MASQ = "m";
      NFT_NAT = "m";
      NFT_REJECT = "m";
      NFT_REJECT_INET = "m";

      NF_CT_PROTO_DCCP = "y";
      NF_CT_PROTO_SCTP = "y";
      NF_CT_PROTO_UDPLITE = "y";
      NF_LOG_SYSLOG = "m";
      NF_NAT = "m";
      NF_NAT_MASQUERADE = "y";
      NF_TABLES = "m";
      NF_TABLES_INET = "y";
      NF_TABLES_IPV4 = "y";
      NF_TABLES_IPV6 = "y";
    };
  };
}
