with import <nixpkgs> {} ;

let
  devices =
    builtins.readDir ../devices;
  texts = lib.mapAttrsToList (n: t:
    let d = import  ../devices/${n}/default.nix;
        d' = {
          description = "no description for ${n}";
        } // d;
        installer =
          if d ? installer
          then ''

            The default installation route for this device is
            :ref:`system-outputs-${d.installer}`
          ''
          else "";
    in (d'.description + installer))
    devices;
in
writeText "hwdoc" ''
  Supported hardware
  ##################

  ${lib.concatStringsSep "\n\n" texts}

''
