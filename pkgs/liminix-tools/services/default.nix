{
  stdenvNoCC
, s6-rc
, s6
, lib
, callPackage
, writeScript
, serviceFns
}:
let
  inherit (builtins) concatStringsSep;
  prefix = "/run/services/outputs";
  output = service: name: "${prefix}/${service.name}/${name}";
  serviceScript = commands : ''
    #!/bin/sh
    exec 2>&1
    . ${serviceFns}
    ${commands}
  '';
  cleanupScript = name : ''
    if test -d ${prefix}/${name} ; then rm -rf ${prefix}/${name} ; fi
  '';
  service = {
    name
    , serviceType
    , run ? null
    , up ? null
    , down ? null
    , outputs ? []
    , notification-fd ? null
    , producer-for ? null
    , consumer-for ? null
    , pipeline-name ? null
    , dependencies ? []
    , contents ? []
    , buildInputs ? []
  } @ args:
    stdenvNoCC.mkDerivation {
      # we use stdenvNoCC to avoid generating derivations with names
      # like foo.service-mips-linux-musl
      inherit name serviceType up down run notification-fd
        producer-for consumer-for pipeline-name;
      buildInputs = buildInputs ++ dependencies ++ contents;
      dependencies = builtins.map (d: d.name) dependencies;
      contents = builtins.map (d: d.name) contents;
      builder = ./builder.sh;
    };

  longrun = {
    name
    , run
    , outputs ? []
    , notification-fd ? null
    , dependencies ? []
    , ...
  } @ args:
    let logger = service {
          serviceType = "longrun";
          name = "${name}-log";
          run = serviceScript "${s6}/bin/s6-log -d 10 -- p${name} 1";
          notification-fd = 10;
          consumer-for = name;
          pipeline-name = "${name}-pipeline";
        };
    in service (args // {
      buildInputs = [ logger ];
      serviceType = "longrun";
      run = serviceScript "${run}\n${cleanupScript name}";
      producer-for = "${name}-log";
    });

  oneshot = {
    name
    , up
    , down ? ""
    , outputs ? []
    , dependencies ? []
    , ...
  } @ args : service (args  // {
    serviceType = "oneshot";
    up = writeScript "${name}-up" (serviceScript up);
    down = writeScript
      "${name}-down"
      "${serviceScript down}\n${cleanupScript name}";
  });
  bundle = {
    name
    , contents ? []
    , dependencies ? []
    , ...
  } @ args: service (args // {
    serviceType = "bundle";
    inherit contents dependencies;
  });
  target = bundle;
in {
  inherit target bundle oneshot longrun output;
}
