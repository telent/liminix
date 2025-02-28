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
  inherit (builtins) concatLists attrValues;
  inherit (liminix) outputRef;
  mkSet =
    family: name:
    nameValuePair "${name}-set-${family}" {
      kind = "set";
      inherit name family;
      type = "ifname";
      elements = map (s: "{{ output(${builtins.toJSON s}, \"ifname\", \"\") }}") zones.${name};
    };
  sets = (mapAttrs' (n: _: mkSet "ip" n) zones) //
         (mapAttrs' (n: _: mkSet "ip6" n) zones);
  allRules = lib.recursiveUpdate extraRules (lib.recursiveUpdate (builtins.trace sets sets) rules);
  script = firewallgen "firewall1.nft" allRules;
  ifwatch = writeFennel "ifwatch" {
    packages = [
      anoia
      lualinux
      linotify
    ];
    mainFunction = "run";
  } ./ifwatch.fnl;
  watchArg = z: intfs: map (i: "${z}:${i}/.outputs") intfs;
  name = "firewall";
  service = longrun {
    inherit name;
    run = ''
      mkdir -p /run/${name}; in_outputs ${name}
      # exec > /dev/console 2>&1
      echo RESTARTING FIREWALL >/dev/console
      PATH=${nftables}/bin:${lua}/bin:$PATH
      ${output-template}/bin/output-template '{{' '}}' < ${script} | lua -e 'for x in io.lines() do if not string.match(x, "elements = {%s+}") then print(x) end; end'   > /run/${name}/fw.nft
      # cat /run/${name}/fw.nft > /dev/console
      nft -f /run/${name}/fw.nft
      while sleep 86400 ; do : ; done
    '';
    finish = "${nftables}/bin/nft flush ruleset";
  };
in
svc.secrets.subscriber.build {
  watch =
    concatLists
      (mapAttrsToList (_zone : services : map (s: outputRef s "ifname") services) zones);

  inherit service;
}
