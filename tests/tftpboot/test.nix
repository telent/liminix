{
  liminix
}:
let check = deviceName : ubootName : config :
let derivation = (import liminix {
      device = import "${liminix}/devices/${deviceName}/";
      liminix-config = { pkgs, ... } : {
        imports = [./configuration.nix];
        inherit config;
      };
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

touch empty empty2

run-liminix-vm \
 --background ./vm \
 --u-boot ${uboot}/u-boot.bin \
 --arch ${derivation.pkgs.stdenv.hostPlatform.qemuArch} \
 --wan "user,tftp=`pwd`" \
 --disk-image empty2 \
 empty empty2

expect ${./script.expect} 2>&1 |tee $out
'';
in {
  aarch64 = check "qemu-aarch64" "ubootQemuAarch64" {};
  arm = check  "qemu-armv7l" "ubootQemuArm" {};
  armZimage = check  "qemu-armv7l" "ubootQemuArm" {
    boot.tftp.kernelFormat = "zimage";
  };
  mips = check  "qemu" "ubootQemuMips" {};
  mipsLz = check  "qemu" "ubootQemuMips" {
    boot.tftp.compressRoot = true;
  };
}
