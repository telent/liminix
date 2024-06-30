{ stdenv, openwrt }:
stdenv.mkDerivation {
  name = "zyxel-bootconfig";
  inherit (openwrt) src;
  sourceRoot = "openwrt-source/package/utils/zyxel-bootconfig/src";
  installPhase = ''
    mkdir -p $out/bin
    install -Dm544 zyxel-bootconfig $out/bin/zyxel-bootconfig
  '';
  meta = {
    mainProgram = "zyxel-bootconfig";
  };
}
