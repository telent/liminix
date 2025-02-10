{
  liminix,
  chrony,
  lib,
  writeText,
}:
params:
let
  name = "ntp"; # bad name, needs to be unique
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep mapAttrsToList;
  configFile =
    p:
    (mapAttrsToList (name: opts: "server ${name} ${concatStringsSep "" opts}") p.servers)
    ++ (mapAttrsToList (name: opts: "pool ${name} ${concatStringsSep "" opts}") p.pools)
    ++ (mapAttrsToList (name: opts: "peer ${name} ${concatStringsSep "" opts}") p.peers)
    ++ lib.optional (p.user != null) "user ${p.user}"
    ++ (lib.optional (
      p.makestep != null
    ) "makestep ${toString p.makestep.threshold} ${toString p.makestep.limit}")
    ++ (map (n: "allow ${n}") p.allow)
    ++ (lib.optional (p.bindaddress != null) "bindaddress ${p.bindaddress}")
    ++ (lib.optional (p.binddevice != null) "binddevice ${p.binddevice}")
    ++ (lib.optional (p.dumpdir != null) "dumpdir ${p.dumpdir}")
    ++ [
      "bindcmdaddress /" # disable unix socket
      "pidfile /run/${name}.pid"
    ]
    ++ [ p.extraConfig ];

  config = writeText "chrony.conf" (concatStringsSep "\n" (configFile params));
in
longrun {
  inherit name;
  run = "${chrony}/bin/chronyd -f ${config} -d";
}
