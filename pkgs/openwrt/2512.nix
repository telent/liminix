{
  fetchFromGitHub,
  pkgsBuildBuild,
  lib,
  cpio
}:
let
  src = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "v25.12.1";
    hash = "sha256-RshgHcH5d1pmS00XPj1DAmfApT4xXrC+QI4Vg2rd/dE=";
  };
  # we don't use different kernel versions for monolith and mac80211 as
  # openwrt does, so we also need an older openwrt version with
  # the wireless patches that correspond to 6.12.x
  oldSrc = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "c8eacec725dce34c7b621f00c9bce814fe413759";
    hash = "sha256-YTfAWmFPXPXFQ56QGRLgCc/QY+RndOdVdcgtBaZsh1E=";
  };
  kernelVersion = "6.12.77";
  kernelSeries = lib.versions.majorMinor kernelVersion;
  doPatch = family: ''
    tar -C ${src}/target/linux/generic/files -cf - . | tar xpf -
    chmod -R u+w .
    tar -C ${src}/target/linux/${family}/files -cf - . | tar xpf -
    chmod -R u+w .
    test -d ${src}/target/linux/${family}/files-${kernelSeries}/ && ( tar -C ${src}/target/linux/${family}/files-${kernelSeries} -cf - . | tar xpf -)
    chmod -R u+w .

    ensure_patch() {
      echo Applying $1
      # skip patches which are already applied by testing if they
      # can be dry-run in reverse
      patch --batch --forward -p1 < $1 ||
        patch --batch --reverse --dry-run -p1 < $1

    }
    patches() {
      for i in $* ; do
         ensure_patch $i
      done
    }

    patches ${src}/target/linux/generic/backport-${kernelSeries}/*.patch
    patches ${src}/target/linux/generic/pending-${kernelSeries}/*.patch
    patches ${src}/target/linux/generic/hack-${kernelSeries}/*.patch
    patches ${src}/target/linux/${family}/patches-${kernelSeries}/*.patch

    for kconfig in $(find drivers/net/wireless/ -name Kconfig); do
      sed -i.bak -E -e '/^((\s+))tristate/a\
\tdepends on m'  $kconfig
    done

    mkdir backport_patches
    for f in ${oldSrc}/package/kernel/mac80211/patches/*.*; do
      out=backport_patches/`basename $f`
      sed < $f 's/CPTCFG_/CONFIG_/g' > $out
      ensure_patch $out
    done
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
    hash = "sha256-kPvUXXvWWmZ+B3ONP7iC2zlwaBom/RCNw6oxXeb47zU=";
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
