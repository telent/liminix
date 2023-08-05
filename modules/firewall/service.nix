{
  liminix
, lib
, firewallgen
, nftables
}:
{ ruleset }:
let
  inherit (liminix.services) oneshot;
  inherit (liminix.lib) typeChecked;
  inherit (lib) mkOption types;
  script = firewallgen "firewall.nft" ruleset;
in oneshot {
  name = "firewall";
  up = script;
  down = "${nftables}/bin/nft flush ruleset";
}
