{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.liminix.services) oneshot;

  kconf = isModule :
    # setting isModule false is utterly untested and mostly
    # unimplemented: I say this to preempt any "how on earth is this
    # even supposed to work?" questions
    let yes = if isModule then "m" else "y";
    in {
      NFT_FIB_IPV4 = yes;
      NFT_FIB_IPV6 = yes;
      NF_TABLES = yes;
      NF_CT_PROTO_DCCP = "y";
      NF_CT_PROTO_SCTP = "y";
      NF_CT_PROTO_UDPLITE = "y";
      # NF_CONNTRACK_FTP = yes;
      NFT_CT = yes;
    };
  kmodules = pkgs.kernel-modules.override {
    kernelSrc = config.system.outputs.kernel.src;
    modulesupport = config.system.outputs.kernel.modulesupport;
    targets = [
      "nft_fib_ipv4"
      "nft_fib_ipv6"
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
      type = types.anything; # types.functionTo pkgs.liminix.lib.types.service;
    };
  };
  config = {
    system.service.firewall = params :
      let svc = (pkgs.callPackage ./service.nix {}) params;
      in svc // { dependencies = svc.dependencies ++ [loadModules]; };

    kernel.config = {
      NETFILTER_XT_MATCH_CONNTRACK = "y";

      IP6_NF_IPTABLES= "y";     # do we still need these
      IP_NF_IPTABLES= "y";      # if using nftables directly

      IP_NF_NAT = "y";
      IP_NF_TARGET_MASQUERADE = "y";
      NETFILTER = "y";
      NETFILTER_ADVANCED = "y";
      NETFILTER_XTABLES = "y";

      NFT_COMPAT = "y";
      NFT_CT = "y";
      NFT_LOG = "y";
      NFT_MASQ = "y";
      NFT_NAT = "y";
      NFT_REJECT = "y";
      NFT_REJECT_INET = "y";

      NF_CONNTRACK = "y";
      NF_NAT = "y";
      NF_NAT_MASQUERADE  = "y";
      NF_TABLES= "y";
      NF_TABLES_INET = "y";
      NF_TABLES_IPV4 = "y";
      NF_TABLES_IPV6 = "y";
    };
  };
}
