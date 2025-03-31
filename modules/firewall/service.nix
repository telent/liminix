{
  liminix,
  lib,
  firewallgen,
  nftables,
  svc,
  lua,
  output-template,
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

  rateHook6 =
    let rules =
          map
            (x: ''
               {{;
                local s = "${x}";
                local n = output(s, "ifname");
                local bw = output(s, "bandwidth");
                if n and bw then
                  return "meta l4proto icmpv6 iifname ".. n .. " limit rate over " .. (math.floor (tonumber(bw) / 8 / 20)) .. " bytes/second drop"
                else
                  return "# " .. (n or "not n") .. " " .. (bw or "not bw")
                end
               }}
             '')
            (concatLists (builtins.attrValues zones));
    in {
      type = "filter"; family = "ip6";
      hook = "input"; priority = "-1"; policy = "accept";
      inherit rules;
    };

  rateHook4 =
    let rules =
          map
            (x: ''
               {{;
                local s = "${x}";
                local n = output(s, "ifname");
                local bw = output(s, "bandwidth");
                if n and bw then
                  return "meta l4proto icmp iifname ".. n .. " limit rate over " .. (math.floor (tonumber(bw) / 8 / 20)) .. " bytes/second drop"
                else
                  return "# " .. (n or "not n") .. " " .. (bw or "not bw")
                end
               }}
             '')
            (concatLists (builtins.attrValues zones));
    in {
      type = "filter"; family = "ip";
      hook = "input"; priority = "-1"; policy = "accept";
      inherit rules;
    };

  sets = (mapAttrs' (n: _: mkSet "ip" n) zones) //
         (mapAttrs' (n: _: mkSet "ip6" n) zones);
  allRules =
    {
      icmp6-ratehook = rateHook6;
      icmp4-ratehook = rateHook4;
    } //
    (lib.recursiveUpdate
      extraRules
      (lib.recursiveUpdate sets rules));
  script = firewallgen "firewall1.nft" allRules;
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
