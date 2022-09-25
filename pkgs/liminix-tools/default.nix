{
  stdenvNoCC
, s6-rc
, lib
, busybox
, callPackage
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
    buildInputs = dependencies ++ contents;
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
    address = interface: { family, prefixLength, address } @ args:
      let inherit (builtins) toString;
      in oneshot {
        dependencies = [ interface ];
        name = "${interface.device}.addr.${address}";
        up = "ip address add ${address}/${toString prefixLength} dev ${interface.device} ";
        down = "ip address del ${address}/${toString prefixLength} dev ${interface.device} ";
      };
    udhcpc = callPackage ./networking/udhcpc.nix {};
    odhcpc = interface: { ... } @ args: longrun {
      name = "${interface.device}.odhcp";
      run = "odhcpcd ${interface.device}";
    };
    pppoe = callPackage ./networking/pppoe.nix {};
  };
  services = {
    inherit longrun oneshot bundle target;
    output = service: name: "/run/s6-rc/scandir/${service.name}/data/outputs/${name}";
  };
}
