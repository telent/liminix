{
  liminix,
  lib,
  firewallgen,
  nftables,
  writeFennel,
  anoia,
  svc,
  lua,
  output-template,
  lualinux,
  linotify,
}:
{
  rules,
  extraRules,
  zones,
}:
let
  inherit (liminix.services) longrun;
  inherit (lib.attrsets) mapAttrs' nameValuePair mapAttrsToList;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists) flatten;
  inherit (builtins) concatLists toJSON attrValues;
  inherit (liminix) outputRef;
  mkSet =
    family: name:
    nameValuePair "${name}-set-${family}" {
      kind = "set";
      inherit name family;
      type = "ifname";
      extraText = ''
      {{;
         local services = { ${concatStringsSep ", " (map toJSON zones.${name})} }
         local ifnames = {}
         for _, v in ipairs(services) do
           local o = output(v, "ifname")
           if o then table.insert(ifnames, o) end
         end
         if (#ifnames > 0) then
           return "elements = { " .. table.concat(ifnames, ", ") .. " }\n"
         else
           return ""
         end
      }}
      '';
  };
  sets = (mapAttrs' (n: _: mkSet "ip" n) zones) //
         (mapAttrs' (n: _: mkSet "ip6" n) zones);
  allRules = lib.recursiveUpdate extraRules (lib.recursiveUpdate sets rules);
  script = firewallgen "firewall1.nft" allRules;
  watchArg = z: intfs: map (i: "${z}:${i}") intfs;
  name = "firewall";
  service = longrun {
    inherit name;
    run = ''
      PATH=${nftables}/bin:${lua}/bin:$PATH
      reload() {
         echo reloading firewall
         ${output-template}/bin/output-template '{{' '}}' < ${script}  > /run/${name}/fw.nft;
         nft -f /run/${name}/fw.nft ;
      }
      trap reload SIGUSR1
      mkdir -p /run/${name}; in_outputs ${name}
      reload
      while :; do
        # signals sent to ash won't interrupt sleep, but will interrupt wait
        sleep 86400 & wait
      done
    '';
    finish = "${nftables}/bin/nft flush ruleset";
  };
in
svc.secrets.subscriber.build {
  action = "usr1";
  watch =
    concatLists
      (mapAttrsToList (_zone : services : map (s: outputRef s "ifname") services) zones);

  inherit service;
}
