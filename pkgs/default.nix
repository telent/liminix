{
  callPackage
}:
{
  pseudofile = callPackage ./pseudofile {};
  liminix = {
    services = callPackage ./liminix-tools/services {};
    networking =  callPackage ./liminix-tools/networking {};
    builders =  {
      squashfs = callPackage ./liminix-tools/builders/squashfs.nix {};
      kernel = callPackage ./kernel {};
    };
  };
  writeAshScript = callPackage ./write-ash-script {};
  systemconfig = callPackage ./systemconfig {};
  s6-init-bin =  callPackage ./s6-init-bin {};
  s6-rc-database = callPackage ./s6-rc-database {};
  mips-vm = callPackage ./mips-vm {};
  pppoe = callPackage ./pppoe {};

  kernel-backport = callPackage ./kernel-backport {};
  mac80211 = callPackage ./mac80211 {};
  netlink-lua = callPackage ./netlink-lua {};
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

  openwrt = callPackage ./openwrt {};

  initramfs-peek = callPackage ./initramfs-peek {};
  min-collect-garbage = callPackage ./min-collect-garbage {};
  min-copy-closure = callPackage ./min-copy-closure {};
  hi = callPackage ./hi {};
}
