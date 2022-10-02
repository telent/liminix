{
  stdenvNoCC
, s6-rc
, lib
, busybox
, callPackage
, writeAshScript
}:
let
  inherit (builtins) concatStringsSep;
  output = service: name: "/run/service-state/${service.name}/${name}";

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
    # stdenvNoCC is to avoid generating derivations with names
    # like foo.service-mips-linux-musl
    inherit name serviceType;
    inherit run up down;
    buildInputs = dependencies ++ contents;
    dependencies = builtins.map (d: d.name) dependencies;
    contents = builtins.map (d: d.name) contents;
    shell = "${busybox}/bin/sh";
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
    up = writeAshScript "${name}-up" {} up;
    down = writeAshScript "${name}-down" {} down;
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
