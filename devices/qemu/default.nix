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
      kernel = prev.kernel.override {
        # using fetchurl not fetchzip because it doesn't unpack, and
        # copying 6GB of data from one store location to another
        # takes an absolute bloody age
        src = final.fetchurl {
          name = "linux.tar.gz";
          url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.19.16.tar.gz";
          hash = "sha256-m4NeoEsCEK0HSIKTZ6zYTgk1fD3W0PSOMXN6fyHpkP8=";
        };
      };
    };

  kernel = {
    config = {
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
