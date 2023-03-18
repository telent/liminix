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
in {
  inherit src;
  applyPatches.ath79 = writeShellScript "apply-patches-ath79" ''
    cp -av ${src}/target/linux/generic/files/* .
    chmod -R u+w .
    cp -av ${src}/target/linux/ath79/files/* .
    chmod -R u+w .
    patches() {
      for i in $* ; do patch --batch --forward -p1 < $i ;done
    }
    patches ${src}/target/linux/generic/backport-5.15/*.patch
    patches ${src}/target/linux/generic/pending-5.15/*.patch
    patches ${src}/target/linux/generic/hack-5.15/*.patch
    patches ${src}/target/linux/ath79/patches-5.15/*.patch
  '';
  applyPatches.ramips = writeShellScript "apply-patches-ramips" ''
    cp -av ${src}/target/linux/generic/files/* .
    chmod -R u+w .
    cp -av ${src}/target/linux/ramips/files/* .
    chmod -R u+w .
    patches() {
      for i in $* ; do patch --batch --forward -p1 < $i ;done
    }
    patches ${src}/target/linux/generic/backport-5.15/*.patch
    patches ${src}/target/linux/generic/pending-5.15/*.patch
    patches ${src}/target/linux/generic/hack-5.15/*.patch
    patches ${src}/target/linux/ramips/patches-5.15/*.patch
  '';
}
