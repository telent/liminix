{
  callPackage

, config
, sources
}:
{
  vmlinux = callPackage ./vmlinux.nix {
    tree = sources.kernel;
    inherit config;
  };

  uimage = callPackage ./uimage.nix { };

  dtb = callPackage ./dtb.nix {
    inherit (sources) openwrt kernel;
  };
}
