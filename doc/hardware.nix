with import <nixpkgs> {} ;

let
  inherit (builtins) stringLength readDir filter;
  devices = filter (n: n != "families")
    (lib.mapAttrsToList (n: t: n) (readDir ../devices));
  texts = map (n:
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
