{ config, pkgs, lib, lim, ... } :
let
  inherit (pkgs.pseudofile) dir symlink;
  dts = pkgs.runCommand "qemu.dts" {
    nativeBuildInputs = with pkgs.pkgsBuildBuild; [ dtc qemu ];
  } ''
      qemu-system-${pkgs.stdenv.hostPlatform.qemuArch} \
        -machine virt -machine dumpdtb=tmp.dtb
      dtc -I dtb -O dts -o $out tmp.dtb
      # https://stackoverflow.com/a/69890137,
      # XXX try fdtput $out -p -t s /pl061@9030000 status disabled
      # instead of using sed
      sed -i $out -e 's/compatible = "arm,pl061.*/status = "disabled";/g'
    '';
in {
  imports = [
    ../../modules/outputs/ext4fs.nix
    ../../modules/outputs/tftpboot.nix
  ];
  config = {
    hardware.dts.src = lib.mkForce dts;
    boot.tftp = {
      loadAddress = lim.parseInt "0x44000000";
      serverip = "10.0.2.2";
      ipaddr = "10.0.2.15";
    };
    boot.imageFormat = "fit";
    rootfsType = "ext4";
    filesystem = dir {
      hello = {
        type = "f";
        uid = 7;
        gid = 24;
        file = "hello world";
      };
    };
  };
}
