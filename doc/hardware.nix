with import <nixpkgs> {} ;

let
  devices = builtins.readDir ../devices;
  inherit (builtins) stringLength;
  texts = lib.mapAttrsToList (n: t:
    let d = import  ../devices/${n}/default.nix;
        d' = {
          description = "${n}\n${substring 0 (stringLength n) "********************************"}\n";
        } // d;
        installer =
          if d ? description && d ? installer
          then ''

            The default installation route for this device is
            :ref:`system-outputs-${d.installer}`
          ''
          else "";
    in d'.description)
    devices;
in
writeText "hwdoc" ''
  Supported hardware
  ##################

  ${lib.concatStringsSep "\n\n" texts}

''
