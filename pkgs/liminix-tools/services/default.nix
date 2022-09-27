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
  longrun = {
    name
    , run
    , outputs ? []
    , notification-fd ? null
    , dependencies ? []
  } @ args: stdenvNoCC.mkDerivation {
    inherit name;
    serviceType = "longrun";
    buildInputs = dependencies;
    dependencies = builtins.map (d: d.name) dependencies;
    shell = "${busybox}/bin/sh";
    inherit run;
    notificationFd = notification-fd;
    builder = ./builder.sh;
  };
  oneshot = {
    name
    , up
    , down
    , outputs ? []
    , dependencies ? []
    , ...
  } @ args: stdenvNoCC.mkDerivation {
    # stdenvNoCC is to avoid generating derivations with names
    # like foo.service-mips-linux-musl
    inherit name;
    serviceType = "oneshot";
    # does this suffice to make sure dependencies are included
    # even though the built output has no references to their
    # store directories?
    buildInputs = dependencies;
    shell = "${busybox}/bin/sh";
    # up and down for oneshots are pathnames not scripts
    up = writeAshScript "${name}-up" {} up;
    down = writeAshScript "${name}-down" {} down;
    dependencies = builtins.map (d: d.name) dependencies;
    builder = ./builder.sh;
  };
  target = {
    name
    , contents ? []
    , dependencies ? []
    , ...
  }: stdenvNoCC.mkDerivation {
    inherit name;
    serviceType = "bundle";
    contents = builtins.map (d: d.name) contents;
    buildInputs = dependencies ++ contents;
    dependencies = builtins.map (d: d.name) dependencies;
    shell = "${busybox}/bin/sh";
    builder = ./builder.sh;
  };
  bundle = { name, ... } @args : target (args // { inherit name;});
in {
  inherit target bundle oneshot longrun output;
}
