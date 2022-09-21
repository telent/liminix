{
  stdenvNoCC
, s6-rc
, lib
, busybox
} :let
  inherit (builtins) concatStringsSep;
  longrun = {
    name
    , run
    , outputs ? []
    , dependencies ? []
  } @ args: stdenvNoCC.mkDerivation {
    name = "${name}.service";
    type = "longrun";
    buildInputs = dependencies;
    dependencies = builtins.map (d: d.name) dependencies;
    shell = "${busybox}/bin/sh";
    inherit run;
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
    name = "${name}.service";
    type = "oneshot";
    # does this suffice to make sure dependencies are included
    # even though the built output has no references to their
    # store directories?
    buildInputs = dependencies;
    shell = "${busybox}/bin/sh";
    inherit up down;
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
    type = "bundle";
    contents = builtins.map (d: d.name) contents;
    buildInputs = dependencies ++ (lib.debug.traceSeqN 2 contents contents);
    dependencies = builtins.map (d: d.name) dependencies;
    shell = "${busybox}/bin/sh";
    builder = ./builder.sh;
  };
  bundle = { name, ... } @args : target (args // { name = "${name}.bundle";});

in {
  networking = {
    interface = { type, device }  @ args: oneshot {
      name = "${device}.link";
      up = "ip link set up dev ${device}";
      down = "ip link set down dev ${device}";
    } // {
      inherit device;
    };
    address = interface: { family, addr } @ args: oneshot {
      dependencies = [ interface ];
      name = "${interface.device}.addr.${addr}";
      up = "ip address add ${addr} dev ${interface.device} ";
      down = "ip address del ${addr} dev ${interface.device} ";
    };
    udhcpc = interface: { ... } @ args: longrun {
      name = "${interface.device}.udhcp";
      run = "${busybox}/bin/udhcpc -f -i ${interface.device}";
    };
    odhcpc = interface: { ... } @ args: longrun {
      name = "${interface.device}.odhcp";
      run = "odhcpcd ${interface.device}";
    };
  };
  services = {
    inherit longrun oneshot bundle target;
    output = service: name: "/run/services/outputs/${service.name}/${name}";
  };
}
