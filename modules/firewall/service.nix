{
  liminix
, lib
, firewallgen
, nftables
}:
{ rules, extraRules }:
let
  inherit (liminix.services) oneshot;
  inherit (liminix.lib) typeChecked;
  inherit (lib) mkOption types;
  script = firewallgen "firewall.nft" (lib.recursiveUpdate rules extraRules);
in oneshot {
  name = "firewall";
  up = script;
  down = "${nftables}/bin/nft flush ruleset";
}
