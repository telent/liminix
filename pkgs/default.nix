{
  callPackage
, lib
}:
let
  typeChecked = caller: type: value:
    let
      inherit (lib) types mergeDefinitions;
      defs = [{ file = caller; inherit value; }];
      type' = types.submodule { options = type; };
    in (mergeDefinitions [] type' defs).mergedValue;
in {
  liminix = {
    builders =  {
      squashfs = callPackage ./liminix-tools/builders/squashfs.nix {};
      dtb = callPackage ./kernel/dtb.nix {};
      uimage = callPackage ./kernel/uimage.nix {};
      kernel = callPackage ./kernel {};
    };
    callService = path : parameters :
      let pkg = callPackage path {};
          checkTypes = t : p : typeChecked (builtins.toString path) t p;
      in {
        inherit parameters;
        build = { dependencies ? [], ... } @ args :
          let
            s = pkg (checkTypes parameters
              (builtins.removeAttrs args ["dependencies"]));
          in s.overrideAttrs (o: {
            dependencies = (builtins.map (d: d.name) dependencies) ++ o.dependencies;
            buildInputs = dependencies ++ o.buildInputs;
          });
      };
    lib = {
      types =
        let inherit (lib) types isDerivation;
        in  rec {
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
        };
      inherit typeChecked;
    };
    networking =  callPackage ./liminix-tools/networking {};
    services = callPackage ./liminix-tools/services {};
  };

  # please keep the rest of this list alphabetised :-)

  anoia = callPackage ./anoia {};
  fennel = callPackage ./fennel {};
  fennelrepl = callPackage ./fennelrepl {};
  firewallgen = callPackage ./firewallgen {};
  firmware-utils = callPackage ./firmware-utils {};
  gen_init_cpio = callPackage ./gen_init_cpio {};
  go-l2tp = callPackage ./go-l2tp {};
  hi = callPackage ./hi {};
  ifwait = callPackage ./ifwait {};
  initramfs-peek = callPackage ./initramfs-peek {};
  kernel-backport = callPackage ./kernel-backport {};
  kmodloader = callPackage ./kmodloader {};
  levitate = callPackage ./levitate {};
  libubootenv = callPackage ./libubootenv {};
  linotify = callPackage ./linotify {};

  # we need to build real lzma instead of using xz, because the lzma
  # decoder in u-boot doesn't understand streaming lzma archives
  # ("Stream with EOS marker is not supported") and xz can't create
  # non-streaming ones.  See
  # https://sourceforge.net/p/squashfs/mailman/message/26599379/
  lzma = callPackage ./lzma {};

  mac80211 = callPackage ./mac80211 {};
  zyxel-bootconfig = callPackage ./zyxel-bootconfig {};
  min-collect-garbage = callPackage ./min-collect-garbage {};
  min-copy-closure = callPackage ./min-copy-closure {};
  nellie = callPackage ./nellie {};
  netlink-lua = callPackage ./netlink-lua {};
  odhcp-script = callPackage ./odhcp-script {};
  odhcp6c = callPackage ./odhcp6c {};
  openwrt = callPackage ./openwrt {};
  ppp = callPackage ./ppp {};
  pppoe = callPackage ./pppoe {};
  preinit = callPackage ./preinit {};
  pseudofile = callPackage ./pseudofile {};
  routeros = callPackage ./routeros {};
  run-liminix-vm = callPackage ./run-liminix-vm {};
  s6-init-bin =  callPackage ./s6-init-bin {};
  s6-rc-database = callPackage ./s6-rc-database {};

  # schnapps is written by Turris and provides a high-level interface
  # to btrfs snapshots. It may be useful on the Turris Omnia to
  # install Liminix while retaining the ability to rollback to the
  # vendor OS, or even to derisk Liminix updates on that device
  schnapps = callPackage ./schnapps {};

  serviceFns = callPackage ./service-fns {};
  swconfig = callPackage ./swconfig {};
  systemconfig = callPackage ./systemconfig {};
  tufted = callPackage ./tufted {};
  uevent-watch = callPackage ./uevent-watch {};
  writeAshScript = callPackage ./write-ash-script {};
  writeFennel = callPackage ./write-fennel {};
  writeFennelScript = callPackage ./write-fennel-script {};
}
