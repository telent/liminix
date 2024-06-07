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
  inherit (builtins) concatStringsSep any map;
  prefix = "/run/services/outputs";
  output = service: name: "${prefix}/${service.name}/${name}";
  serviceScript = commands : ''
    #!/bin/sh
    exec 2>&1
    . ${serviceFns}
    ${commands}
  '';
  cleanupScript = name : ''
    #!/bin/sh
    if test -d ${prefix}/${name} ; then rm -rf ${prefix}/${name} ; fi
  '';
  service = {
    name
    , serviceType
    , run ? null
    , up ? null
    , down ? null
    , finish ? null
    , outputs ? []
    , notification-fd ? null
    , producer-for ? null
    , consumer-for ? null
    , pipeline-name ? null
    , timeout-up ? 30000        # milliseconds
    , timeout-down ? 0
    , dependencies ? []
    , contents ? []
    , buildInputs ? []
    , isTrigger ? false
  } @ args:
    stdenvNoCC.mkDerivation {
      # we use stdenvNoCC to avoid generating derivations with names
      # like foo.service-mips-linux-musl
      inherit name serviceType up down run finish notification-fd
        producer-for consumer-for pipeline-name timeout-up timeout-down;
      restart-on-upgrade = isTrigger;
      buildInputs = buildInputs ++ dependencies ++ contents;
      dependencies = map (d: d.name) dependencies;
      contents = map (d: d.name) contents;
      builder = ./builder.sh;
    };

  longrun = {
    name
    , run
    , outputs ? []
    , notification-fd ? null
    , dependencies ? []
    , buildInputs ? []
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
      buildInputs = buildInputs ++ [ logger ];
      serviceType = "longrun";
      run = serviceScript run;
      finish = cleanupScript name;
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
