{
  liminix
, lib
, firewallgen
, nftables
}:
let
  inherit (liminix.services) oneshot;
  inherit (liminix.lib) typeChecked;
  inherit (lib) mkOption types;
  t = {
    ruleset = mkOption {
      type = types.anything;         # we could usefully define this more tightly
      description = "firewall ruleset";
    };
  };
in
params:
let
  inherit (typeChecked "firewall" t params) ruleset;
  script = firewallgen "firewall.nft" ruleset;
in oneshot {
  name = "firewall";
  up = script;
  down = "${nftables}/bin/nft flush ruleset";
}
