{ fetchFromGitHub, pkgsBuildBuild }:
let
  src = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "refs/tags/v23.05.2";
    hash = "sha256-kP+cSOB6LiOMWs7g+ji7P7ehiDYDwRdmT4R5jSzw6K4=";
  };
  doPatch = family: ''
    cp -av ${src}/target/linux/generic/files/* .
    chmod -R u+w .
    cp -av ${src}/target/linux/${family}/files/* .
    chmod -R u+w .
    test -d ${src}/target/linux/${family}/files-5.15/ && cp -av ${src}/target/linux/${family}/files-5.15/* .
    chmod -R u+w .
    patches() {
      for i in $* ; do patch --batch --forward -p1 < $i ;done
    }
    patches ${src}/target/linux/generic/backport-5.15/*.patch
    patches ${src}/target/linux/generic/pending-5.15/*.patch
    # This patch breaks passing the DTB to kexeced kernel, so let's
    # get rid of it. It's not needed anyway as we pass the cmdline
    # in the dtb
    patch --batch -p1 --reverse <  ${src}/target/linux/generic/pending-5.15/330-MIPS-kexec-Accept-command-line-parameters-from-users.patch
    patches ${src}/target/linux/generic/hack-5.15/*.patch
    patches ${src}/target/linux/${family}/patches-5.15/*.patch
    patches ${./make-mtdsplit-jffs2-endian-agnostic.patch}
  '';
in {
  inherit src;

  # The kernel sources typically used with this version of openwrt
  # You can find this in `include/kernel-5.15` or similar in the
  # openwrt sources
  kernelSrc = pkgsBuildBuild.fetchurl {
    name = "linux.tar.gz";
    url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.137.tar.gz";
    hash = "sha256-PkdzUKZ0IpBiWe/RS70J76JKnBFzRblWcKlaIFNxnHQ=";
  };
  kernelVersion = "5.15.137";

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
