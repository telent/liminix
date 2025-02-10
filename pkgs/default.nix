{ callPackage, lib }:
let
  typeChecked =
    caller: type: value:
    let
      inherit (lib) types mergeDefinitions;
      defs = [
        {
          file = caller;
          inherit value;
        }
      ];
      type' = types.submodule { options = type; };
    in
    (mergeDefinitions [ ] type' defs).mergedValue;
in
{
  liminix = {
    builders = {
      squashfs = callPackage ./liminix-tools/builders/squashfs.nix { };
      dtb = callPackage ./kernel/dtb.nix { };
      uimage = callPackage ./kernel/uimage.nix { };
      kernel = callPackage ./kernel { };
    };
    outputRef =
      service: path:
      let
        h = { inherit service path; };
      in
      x: h.${x};
    callService =
      path: parameters:
      let
        pkg = callPackage path { };
        checkTypes = t: p: typeChecked (builtins.toString path) t p;
      in
      {
        inherit parameters;
        build =
          {
            dependencies ? [ ],
            ...
          }@args:
          let
            s = pkg (checkTypes parameters (builtins.removeAttrs args [ "dependencies" ]));
          in
          s.overrideAttrs (o: {
            dependencies = dependencies ++ o.dependencies;
            buildInputs = dependencies ++ o.buildInputs;
          });
      };
    lib = {
      types =
        let
          inherit (lib) mkOption types isDerivation;
        in
        rec {
          service = types.package // {
            name = "service";
            description = "s6-rc service";
            check = x: isDerivation x && x ? serviceType;
          };
          interface = service;
          serviceDefn = types.attrs // {
            name = "service-defn";
            description = "parametrisable s6-rc service definition";
            check = x: lib.isAttrs x && x ? parameters && x ? build;
          };
          replacable =
            t:
            types.either t
              # function might return a service or a path
              (types.functionTo types.anything);
        };
      inherit typeChecked;
    };
    networking = callPackage ./liminix-tools/networking { };
    services = callPackage ./liminix-tools/services { };
  };

  # please keep the rest of this list alphabetised :-)

  anoia = callPackage ./anoia { };
  certifix-client = callPackage ./certifix-client { };
  devout = callPackage ./devout { };
  fetch-freebsd = callPackage ./fetch-freebsd { };
  fennel = callPackage ./fennel { };
  fennelrepl = callPackage ./fennelrepl { };
  firewallgen = callPackage ./firewallgen { };
  firmware-utils = callPackage ./firmware-utils { };
  gen_init_cpio = callPackage ./gen_init_cpio { };
  go-l2tp = callPackage ./go-l2tp { };
  hi = callPackage ./hi { };
  ifwait = callPackage ./ifwait { };
  initramfs-peek = callPackage ./initramfs-peek { };
  incz = callPackage ./incz { };
  json-to-fstree = callPackage ./json-to-fstree { };
  kernel-backport = callPackage ./kernel-backport { };
  kmodloader = callPackage ./kmodloader { };
  levitate = callPackage ./levitate { };
  libubootenv = callPackage ./libubootenv { };
  linotify = callPackage ./linotify { };
  logshipper = callPackage ./logshipper { };
  lualinux = callPackage ./lualinux { };

  # we need to build real lzma instead of using xz, because the lzma
  # decoder in u-boot doesn't understand streaming lzma archives
  # ("Stream with EOS marker is not supported") and xz can't create
  # non-streaming ones.  See
  # https://sourceforge.net/p/squashfs/mailman/message/26599379/
  lzma = callPackage ./lzma { };

  mac80211 = callPackage ./mac80211 { };
  zyxel-bootconfig = callPackage ./zyxel-bootconfig { };
  min-collect-garbage = callPackage ./min-collect-garbage { };
  min-copy-closure = callPackage ./min-copy-closure { };
  minisock = callPackage ./minisock { };
  nellie = callPackage ./nellie { };
  netlink-lua = callPackage ./netlink-lua { };
  nginx-small = callPackage ./nginx-small { };
  odhcp-script = callPackage ./odhcp-script { };
  odhcp6c = callPackage ./odhcp6c { };
  openwrt = callPackage ./openwrt { };
  openwrt_24_10 = callPackage ./openwrt/2410.nix { };
  output-template = callPackage ./output-template { };
  ppp = callPackage ./ppp { };
  pppoe = callPackage ./pppoe { };
  preinit = callPackage ./preinit { };
  pseudofile = callPackage ./pseudofile { };
  routeros = callPackage ./routeros { };
  rxi-json = callPackage ./rxi-json { };
  run-liminix-vm = callPackage ./run-liminix-vm { };
  s6-init-bin = callPackage ./s6-init-bin { };
  s6-rc-database = callPackage ./s6-rc-database { };
  s6-rc-round-robin = callPackage ./s6-rc-round-robin { };
  s6-rc-up-tree = callPackage ./s6-rc-up-tree { };

  # schnapps is written by Turris and provides a high-level interface
  # to btrfs snapshots. It may be useful on the Turris Omnia to
  # install Liminix while retaining the ability to rollback to the
  # vendor OS, or even to derisk Liminix updates on that device
  schnapps = callPackage ./schnapps { };

  seedrng = callPackage ./seedrng { };
  serviceFns = callPackage ./service-fns { };
  swconfig = callPackage ./swconfig { };
  systemconfig = callPackage ./systemconfig { };
  tangc = callPackage ./tangc { };
  tufted = callPackage ./tufted { };
  uevent-watch = callPackage ./uevent-watch { };
  usb-modeswitch = callPackage ./usb-modeswitch { };
  watch-outputs = callPackage ./watch-outputs { };
  watch-ssh-keys = callPackage ./watch-ssh-keys { };
  writeAshScript = callPackage ./write-ash-script { };
  writeAshScriptBin = callPackage ./write-ash-script/bin.nix { };
  writeFennel = callPackage ./write-fennel { };
}
