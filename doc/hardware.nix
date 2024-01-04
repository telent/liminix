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

  For development, the `GL.iNet GL-MT300A <https://www.gl-inet.com/products/gl-mt300a/>`_
  is an attractive choice as it has a builtin "debrick" procedure in the
  boot monitor and is also comparatively simple to
  attach serial cables to (soldering not required), so it
  is lower-risk than some devices.

  For a more powerful device, something with an ath10k would be the safe bet,
  or the Linksys E8450 which seems popular in the openwrt community.

  ${lib.concatStringsSep "\n\n" texts}

''
