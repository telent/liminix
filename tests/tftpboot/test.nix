{
  liminix
}:
let check = deviceName : ubootName :
let derivation = (import liminix {
      device = import "${liminix}/devices/${deviceName}/";
      liminix-config = ./configuration.nix;
    });
    img = derivation.outputs.tftpboot;
    uboot = derivation.pkgs.${ubootName};
    pkgsBuild = derivation.pkgs.pkgsBuildBuild;
in pkgsBuild.runCommand "check" {
  nativeBuildInputs = with pkgsBuild; [
    expect
    socat
    run-liminix-vm
  ] ;
} ''
mkdir vm
ln -s ${img} result

run-liminix-vm \
 --background ./vm \
 --u-boot ${uboot}/u-boot.bin \
 --arch ${derivation.pkgs.stdenv.hostPlatform.qemuArch} \
 --wan "user,tftp=`pwd`" \
 --disk-image result/rootfs \
 result/uimage result/rootfs

expect ${./script.expect} 2>&1 |tee $out
'';
in {
  arm = check  "qemu-armv7l" "ubootQemuArm";
  aarch64 = check "qemu-aarch64" "ubootQemuAarch64";
}
