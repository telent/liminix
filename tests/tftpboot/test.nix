{
  liminix
}:
let check = deviceName  : config :
let derivation = (import liminix {
      device = import "${liminix}/devices/${deviceName}/";
      liminix-config = { pkgs, ... } : {
        imports = [./configuration.nix];
        inherit config;
      };
    });
    img = derivation.outputs.tftpboot;
    uboot = derivation.outputs.u-boot;
    pkgsBuild = derivation.pkgs.pkgsBuildBuild;
in pkgsBuild.runCommand "check-${deviceName}" {
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
  aarch64 = check "qemu-aarch64" {};
  arm = check  "qemu-armv7l" {};
  armZimage = check  "qemu-armv7l" {
    boot.tftp.kernelFormat = "zimage";
  };
  mips = check  "qemu" {};
  mipsLz = check  "qemu" {
    boot.tftp.compressRoot = true;
  };
  # this works on real hardware but I haven't figured out how
  # to make it work on qemu: it says
  # "OF: fdt: No chosen node found, continuing without"

  # mipsOldUboot = check  "qemu" {
  #   boot.tftp.appendDTB = true;
  # };
}
