{
  liminix,
  lib,
  s6-rc-round-robin,
}:
{ services, name }:
let
  inherit (liminix.services) oneshot longrun;
  controlled-services = builtins.map (
    s:
    s.overrideAttrs (o: {
      inherit controller;
    })
  ) services;
  controller =
    let
      name' = "control-${name}";
    in
    longrun {
      name = name';
      run = ''
        in_outputs ${name'}
        exec ${s6-rc-round-robin}/bin/s6-rc-round-robin \
           -p ${proxy.name} \
           ${lib.concatStringsSep " " (builtins.map (f: f.name) controlled-services)}
      '';
    };
  proxy = oneshot rec {
    inherit name;
    inherit controller;
    buildInputs = controlled-services;
    up = ''
      echo start proxy ${name}
      set -x
      (in_outputs ${name}
       cp -rv $(output_path ${controller} active)/* .
      )
    '';
  };
in
proxy
