{
  liminix
}:
let derivation = (import liminix {
      device = import "${liminix}/devices/qemu-armv7l/";
      liminix-config = ./configuration.nix;
    });
    img = derivation.outputs.tftpboot;
    pkgs = derivation.pkgs;
    pkgsBuild = pkgs.pkgsBuildBuild;
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
 --u-boot ${pkgs.ubootQemuArm}/u-boot.bin \
 --arch arm \
 --flag -S \
 --phram-address 0x40200000 \
 --lan "user,tftp=`pwd`" \
 --disk-image result/rootfs \
 result/uimage result/rootfs

expect ${./script.expect} 2>&1 |tee $out
''
