{ config, pkgs, lib, lim, ... } :
let
  inherit (pkgs.pseudofile) dir symlink;
  dts = pkgs.runCommand "qemu.dts" {
    nativeBuildInputs = with pkgs.pkgsBuildBuild; [ dtc qemu ];
  } ''
      qemu-system-arm -machine virt -machine dumpdtb=tmp.dtb
      dtc -I dtb -O dts -o $out tmp.dtb
    '';
in {
  imports = [
    ../../modules/outputs/ext4fs.nix
    ../../modules/outputs/tftpboot.nix
  ];
  config = {
    hardware.dts.src = lib.mkForce dts;
    boot.tftp = {
      loadAddress = lim.parseInt "0x42000000";
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
