{
  fetchFromGitHub,
  pkgsBuildBuild,
  lib,
}:
let
  src = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "refs/tags/v24.10.0-rc4";
    hash = "sha256-7edkUCTfGnZeMWr/aXoQrP4I47iXhMi/gUxO2SR+Ylc=";
  };
  kernelVersion = "6.6.67";
  kernelSeries = lib.versions.majorMinor kernelVersion;
  doPatch = family: ''
    cp -av ${src}/target/linux/generic/files/* .
    chmod -R u+w .
    cp -av ${src}/target/linux/${family}/files/* .
    chmod -R u+w .
    test -d ${src}/target/linux/${family}/files-${kernelSeries}/ && cp -av ${src}/target/linux/${family}/files-${kernelSeries}/* .
    chmod -R u+w .
    patches() {
      for i in $* ; do patch --batch --forward -p1 < $i ;done
    }
    patches ${src}/target/linux/generic/backport-${kernelSeries}/*.patch
    patches ${src}/target/linux/generic/pending-${kernelSeries}/*.patch
    patches ${src}/target/linux/generic/hack-${kernelSeries}/*.patch
    patches ${src}/target/linux/${family}/patches-${kernelSeries}/*.patch
    patches \
      ${./make-mtdsplit-jffs2-endian-agnostic.patch} \
      ${./fix-mtk-wed-bm-desc-ptr.patch} 
  '';
in
{
  inherit src;

  # The kernel sources typically used with this version of openwrt
  # You can find this in `include/kernel-5.15` or similar in the
  # openwrt sources
  kernelSrc = pkgsBuildBuild.fetchurl {
    name = "linux.tar.gz";
    url = "https://cdn.kernel.org/pub/linux/kernel/v${lib.versions.major kernelVersion}.x/linux-${kernelVersion}.tar.gz";
    hash = "sha256-Vj6O6oa83xzAF3FPl6asQK2Zrl7PaBCVjcUDq93caL4=";
  };
  inherit kernelVersion;

  applyPatches.ath79 = doPatch "ath79";
  applyPatches.ramips = doPatch "ramips";
  applyPatches.mediatek = doPatch "mediatek"; # aarch64
  applyPatches.mvebu = doPatch "mvebu"; # arm

  applyPatches.rt2x00 = ''
    PATH=${pkgsBuildBuild.patchutils}/bin:$PATH
    for i in ${src}/package/kernel/mac80211/patches/rt2x00/6*.patch ; do
      fixed=$(basename $i).fixed
      sed '/depends on m/d'  < $i | sed 's/CPTCFG_/CONFIG_/g' | recountdiff | filterdiff -x '*/local-symbols' > $fixed
      case $fixed in
        606-*)
          ;;
        611-*)
          filterdiff -x '*/rt2x00.h' < $fixed | patch --forward -p1
          ;;
        601-*|607-*)
          filterdiff -x '*/rt2x00_platform.h' < $fixed | patch --forward -p1
          ;;
        *)
          cat $fixed | patch --forward -p1
          ;;
      esac
    done
  '';
}
