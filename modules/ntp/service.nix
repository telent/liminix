{
  liminix
, chrony
, serviceFns
, lib
, writeText
}:
let
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep mapAttrsToList;
  inherit (liminix.lib) typeChecked;
  inherit (lib) mkOption types;

  serverOpts = types.listOf types.str;
  t = {
    user = mkOption {
      type = types.str;
      default = "ntp";
    };
    servers = mkOption { type = types.attrsOf serverOpts; default = {}; };
    pools = mkOption { type = types.attrsOf serverOpts; default = {}; };
    peers = mkOption { type = types.attrsOf serverOpts; default = {}; };
    makestep = {
      threshold = mkOption { type = types.number; };
      limit = mkOption { type = types.number; };
    };
    allow = mkOption {
      description = "subnets from which NTP clients are allowed to access the server";
      type = types.listOf types.str;
      default = [];
    };
    bindaddress = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    binddevice = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    dumpdir = mkOption {
      internal = true;
      type = types.path;
      default = "/run/chrony";
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
    };
  };
  configFile = p:
    (mapAttrsToList (name: opts: "server ${name} ${concatStringsSep "" opts}")
      p.servers)
    ++
    (mapAttrsToList (name: opts: "pool ${name} ${concatStringsSep "" opts}")
      p.pools)
    ++
    (mapAttrsToList (name: opts: "peer ${name} ${concatStringsSep "" opts}")
      p.peers)
    ++ [ "user #{p.user}" ]
    ++ (lib.optional (p.makestep != null) "makestep ${toString p.makestep.threshold} ${toString p.makestep.limit}")
    ++ (map (n: "allow ${n}") p.allow)
    ++ (lib.optional (p.bindaddress != null) "bindaddress ${p.bindaddress}")
    ++ (lib.optional (p.binddevice != null) "binddevice ${p.binddevice}")
    ++ (lib.optional (p.dumpdir != null) "dumpdir ${p.dumpdir}")
    ++ [p.extraConfig];
in
params:
let
  config = writeText "chrony.conf"
    (concatStringsSep "\n"
      (configFile (typeChecked "" t params)));
in longrun {
  name = "ntp"; # bad name, needs to be unique
  run = "${chrony}/bin/chronyd -f ${config} -d";
}
