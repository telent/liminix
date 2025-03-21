{
  nftables,
  writeScript,
  lib,
}:
name: ruleset:
let
  inherit (lib.strings)
    concatStringsSep
    splitString
    hasInfix
    substring
    optionalString
    ;
  inherit (lib.lists) groupBy;
  inherit (lib.attrsets) attrsToList mapAttrsToList;
  inherit (builtins) elemAt map head tail toString;

  indentLines =
    offset: lines:
    if lines == [ ] then
      ""
    else
      let
        line = head lines;
        isOpen = hasInfix "{" line;
        isClose = hasInfix "}" line;
        offset' = offset + (if isOpen then 4 else 0) + (if isClose then -4 else 0);
        padding = offset: substring 0 offset "                           ";
      in
      if (isClose && !isOpen) then
        (padding offset') + line + "\n" + indentLines offset' (tail lines)
      else
        (padding offset) + line + "\n" + indentLines offset' (tail lines);

  indent = text: indentLines 0 (splitString "\n" text);

  dochain =
    {
      name,
      type,
      family,
      rules,
      policy ? null,
      priority ? "filter",
      hook ? null,
    }:
    ''
      chain ${name} {
      ${if hook != null then "type ${type} hook ${hook} priority ${priority}; policy ${policy};" else ""}
      ${concatStringsSep "\n" rules}
      }
    '';

  doset =
    {
      name,
      type,
      elements ? [ ],
      extraText ? null,
      ...
    }:
    ''
      set ${name}  {
        type ${type}
        ${if elements != [ ] then "elements = { ${concatStringsSep ", " (builtins.trace elements elements)} }" else ""}
        ${optionalString (extraText != null) extraText}
      }
    '';

  domap =
    {
      name,
      type,
      elements ? [ ],
      extraText ? null,
      ...
    }:
      let
        colonize = v:
          let  ty = elemAt (attrsToList v) 0; in "${ty.name}: ${ty.value}";
      in ''
        map ${name}  {
          type ${colonize type}
          ${if elements != [ ] then "elements = { ${concatStringsSep ", " (mapAttrsToList (k: v : "${k}: ${toString v}") elements)} }" else ""}
          ${optionalString (extraText != null) extraText}
        }
      '';

  dochainorset =
    {
      kind ? "chain",
      ...
    }@params:
    {
      chain = dochain;
      set = doset;
      map = domap;
    }
    .${kind}
      params;

  dotable = family: chains: ''
    table ${family} table-${family} {
    ${concatStringsSep "\n" (map dochainorset chains)}
    }
  '';
  categorise =
    chains: groupBy ({ family, ... }: family) (mapAttrsToList (n: v: { name = n; } // v) chains);
in
writeScript name ''
  #!${nftables}/sbin/nft -f

  flush ruleset

  ${indent (concatStringsSep "\n" (mapAttrsToList dotable (categorise ruleset)))}
''
