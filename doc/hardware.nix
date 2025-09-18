with import <nixpkgs> { };

let
  inherit (builtins) stringLength readDir filter;
  devices = filter (n: n != "families") (lib.mapAttrsToList (n: t: n) (readDir ../devices));
  texts = map (
    n:
    let
      d = import ../devices/${n}/default.nix;
      tag = ".. _${lib.strings.replaceStrings [ " " ] [ "-" ] n}:";
      d' = {
        description = ''
          == ${n}
        '';
      } // d;
    in
    "\n${d'.description}"
  ) devices;
in
writeText "hwdoc" ''
  ${lib.concatStringsSep "\n\n" texts}

''
