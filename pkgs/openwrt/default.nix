{
  fetchFromGitHub
, writeShellScript
}:
let
  src = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "a5265497a4f6da158e95d6a450cb2cb6dc085cab";
    hash = "sha256-YYi4gkpLjbOK7bM2MGQjAyEBuXJ9JNXoz/JEmYf8xE8=";
  };
  doPatch = family : ''
    cp -av ${src}/target/linux/generic/files/* .
    chmod -R u+w .
    cp -av ${src}/target/linux/${family}/files/* .
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
}
