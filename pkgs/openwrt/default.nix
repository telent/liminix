{
  fetchFromGitHub
, writeShellScript
}:
let
  src = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "refs/tags/v23.05.2";
    hash = "sha256-kP+cSOB6LiOMWs7g+ji7P7ehiDYDwRdmT4R5jSzw6K4=";
  };
  doPatch = family : ''
    cp -av ${src}/target/linux/generic/files/* .
    chmod -R u+w .
    cp -av ${src}/target/linux/${family}/files/* .
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
  applyPatches.ath79 = doPatch "ath79";
  applyPatches.ramips = doPatch "ramips";
  applyPatches.mediatek = doPatch "mediatek"; # aarch64
  applyPatches.mvebu = doPatch "mvebu"; # arm
}
