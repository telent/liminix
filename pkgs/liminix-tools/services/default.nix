{
  stdenvNoCC
, s6-rc
, lib
, busybox
, callPackage
, writeScript
}:
let
  inherit (builtins) concatStringsSep;
  output = service: name: "/run/service-state/${service.name}/${name}";
  serviceScript = commands : ''
    #!${busybox}/bin/sh
    output() { cat $1/.outputs/$2; }
    ${commands}
  '';
  service = {
    name
    , serviceType
    , run ? null
    , up ? null
    , down ? null
    , outputs ? []
    , notification-fd ? null
    , dependencies ? []
    , contents ? []
  } @ args: stdenvNoCC.mkDerivation {
    # we use stdenvNoCC to avoid generating derivations with names
    # like foo.service-mips-linux-musl
    inherit name serviceType up down run;
    buildInputs = dependencies ++ contents;
    dependencies = builtins.map (d: d.name) dependencies;
    contents = builtins.map (d: d.name) contents;
    notificationFd = notification-fd;
    builder = ./builder.sh;
  };

  longrun = {
    name
    , run
    , outputs ? []
    , notification-fd ? null
    , dependencies ? []
  } @ args: service (args //{
    serviceType = "longrun";
    run = serviceScript run;
  });
  oneshot = {
    name
    , up
    , down
    , outputs ? []
    , dependencies ? []
    , ...
  } @ args : service (args  // {
    serviceType = "oneshot";
    up = writeScript "${name}-up" (serviceScript up);
    down= writeScript "${name}-down" (serviceScript down);
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
