with import <nixpkgs> {} ;

let
  devices =
    builtins.readDir ../devices;
  texts = lib.mapAttrsToList (n: t:
    let d = import  ../devices/${n}/default.nix;
        d' = { description = "no description for ${n}"; } // d;
    in d'.description )
    devices;
in
writeText "hwdoc" ''
  Supported hardware
  ##################

  ${lib.concatStringsSep "\n\n" texts}

''
