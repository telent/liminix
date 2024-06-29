{
  liminix
, lib
, firewallgen
, nftables
}:
{ rules, extraRules }:
let
  inherit (liminix.services) oneshot;
  script = firewallgen "firewall.nft" (lib.recursiveUpdate rules extraRules);
in oneshot {
  name = "firewall";
  up = script;
  down = "${nftables}/bin/nft flush ruleset";
}
