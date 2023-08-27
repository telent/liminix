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
  pseudofile = callPackage ./pseudofile {};
  liminix = {
    services = callPackage ./liminix-tools/services {};
    networking =  callPackage ./liminix-tools/networking {};
    builders =  {
      squashfs = callPackage ./liminix-tools/builders/squashfs.nix {};
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
  };
  writeFennelScript = callPackage ./write-fennel-script {};
  writeAshScript = callPackage ./write-ash-script {};
  systemconfig = callPackage ./systemconfig {};
  s6-init-bin =  callPackage ./s6-init-bin {};
  s6-rc-database = callPackage ./s6-rc-database {};
  mips-vm = callPackage ./mips-vm {};
  ppp = callPackage ./ppp {};
  pppoe = callPackage ./pppoe {};

  kernel-backport = callPackage ./kernel-backport {};
  mac80211 = callPackage ./mac80211 {};
  netlink-lua = callPackage ./netlink-lua {};
  linotify = callPackage ./linotify {};
  ifwait = callPackage ./ifwait {};

  gen_init_cpio = callPackage ./gen_init_cpio {};

  serviceFns = callPackage ./service-fns {};

  # these are packages for the build system not the host/target

  tufted = callPackage ./tufted {};
  routeros = callPackage ./routeros {};
  go-l2tp = callPackage ./go-l2tp {};

  # we need to build real lzma instead of using xz, because the lzma
  # decoder in u-boot doesn't understand streaming lzma archives
  # ("Stream with EOS marker is not supported") and xz can't create
  # non-streaming ones.  See
  # https://sourceforge.net/p/squashfs/mailman/message/26599379/
  lzma = callPackage ./lzma {};

  preinit = callPackage ./preinit {};
  swconfig = callPackage ./swconfig {};
  odhcp6c = callPackage ./odhcp6c {};

  openwrt = callPackage ./openwrt {};

  initramfs-peek = callPackage ./initramfs-peek {};
  min-collect-garbage = callPackage ./min-collect-garbage {};
  min-copy-closure = callPackage ./min-copy-closure {};
  hi = callPackage ./hi {};
  firewallgen  = callPackage ./firewallgen {};
  kernel-modules  = callPackage ./kernel-modules {};
  odhcp-script = callPackage ./odhcp-script {};
  fennel = callPackage ./fennel {};
  fennelrepl = callPackage ./fennelrepl {};
  anoia = callPackage ./anoia {};
}
