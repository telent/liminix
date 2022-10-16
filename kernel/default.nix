{
  callPackage

, config
, checkedConfig
, sources
}:
{
  vmlinux = callPackage ./vmlinux.nix {
    tree = sources.kernel;
    inherit config checkedConfig;
  };

  uimage = callPackage ./uimage.nix { };

  dtb = callPackage ./dtb.nix {
    inherit (sources) openwrt kernel;
  };
}
