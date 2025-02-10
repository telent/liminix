{
  liminix
, lib
, firewallgen
, nftables
, writeFennel
, anoia
, lualinux
, linotify
}:
{ rules, extraRules, zones }:
let
  inherit (liminix.services) longrun;
  inherit (lib.attrsets) mapAttrs' nameValuePair mapAttrsToList;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists) flatten;
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
  ifwatch = writeFennel "ifwatch" {
    packages = [anoia lualinux linotify];
    mainFunction = "run";
  } ./ifwatch.fnl ;
  watchArg = z : intfs : map (i: "${z}:${i}/.outputs") intfs;
in longrun {
  name = "firewall";
  run = ''
    ${script}
    PATH=${nftables}/bin:$PATH
    ${ifwatch} ${concatStringsSep " " (flatten (mapAttrsToList watchArg zones))}
  '';
  finish = "${nftables}/bin/nft flush ruleset";
}
