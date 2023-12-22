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
    hostname = "tftpboot-test";
    # use extracted dts if it was null in the device
    # definition, use actual dts if provided
    hardware.dts.src = lib.mkOverride 500 dts;
    boot.tftp = {
      loadAddress =
        let offsets = {
              mips = "0x88000000";
              arm = "0x44000000";
              aarch64 = "0x44000000";
            };
        in lim.parseInt offsets.${pkgs.stdenv.hostPlatform.qemuArch} ;
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
