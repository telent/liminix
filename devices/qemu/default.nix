# This "device" generates images that can be used with the QEMU
# emulator. The default output is a directory containing separate
# kernel (uncompressed vmlinux) and initrd (squashfs) images

{
  system = {
    crossSystem = {
      config = "mips-unknown-linux-musl";
      gcc = {
        abi = "32";
        arch = "mips32";          # maybe mips_24kc-
      };
    };
  };

  overlay = final: prev:
    let inherit (final) stdenvNoCC fetchFromGitHub;
    in {
      sources = {
        kernel =
          let src = fetchFromGitHub {
                name = "kernel-source";
                owner = "torvalds";
                repo = "linux";
                rev = "3d7cb6b04c3f3115719235cc6866b10326de34cd";  # v5.19
                hash = "sha256-OVsIRScAnrPleW1vbczRAj5L/SGGht2+GnvZJClMUu4=";
              };
          in  stdenvNoCC.mkDerivation {
            name = "spindled-kernel-tree";
            inherit src;
            phases = [
              "unpackPhase"
              "patchScripts" "installPhase"
            ];

            patchScripts = ''
              patchShebangs scripts/
            '';
            installPhase = ''
              mkdir -p $out
              cp -a . $out
            '';
          };
      };
    };

  kernel = {
    checkedConfig = {
      MIPS_MALTA= "y";
      CPU_LITTLE_ENDIAN= "n";
      CPU_BIG_ENDIAN= "y";
      CPU_MIPS32_R2= "y";

      SQUASHFS = "y";
      SQUASHFS_XZ = "y";

      VIRTIO_MENU = "y";
      PCI = "y";
      VIRTIO_PCI = "y";
      BLOCK = "y";
      VIRTIO_BLK = "y";
      NETDEVICES = "y";
      VIRTIO_NET = "y";

      SERIAL_8250= "y";
      SERIAL_8250_CONSOLE= "y";
    };
  };
  outputs.default = "directory";
}
