{
  liminix
, lib
, firewallgen
, nftables
}:
{ rules, extraRules, zones }:
let
  inherit (liminix.services) longrun ; # oneshot;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  mkSet = family : name :
    nameValuePair
      "${name}-set-${family}"
      {
        kind = "set";
        inherit name family;
        type = "ifname";
      };
  sets = (mapAttrs' (n : _ : mkSet "ip" n) zones) //
         (mapAttrs' (n : _ : mkSet "ip6" n) zones);
  allRules = lib.recursiveUpdate extraRules (lib.recursiveUpdate (builtins.trace sets sets) rules);
  script = firewallgen "firewall1.nft" allRules;

in longrun {
  name = "firewall";
  run = ''
    ${script}
    while : ; do sleep 86400 ; done
  '';
  finish = "${nftables}/bin/nft flush ruleset";
}
