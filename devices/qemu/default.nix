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

  module = {pkgs, config, ... }: {
    kernel = {
      src = pkgs.pkgsBuildBuild.fetchurl {
        name = "linux.tar.gz";
        url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
        hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
      };
      config = {
        MIPS_MALTA= "y";
        CPU_LITTLE_ENDIAN= "n";
        CPU_BIG_ENDIAN= "y";
        CPU_MIPS32_R2= "y";

        MTD = "y";
        MTD_BLOCK2MTD = "y";
        MTD_BLKDEVS = "y";
        MTD_BLOCK = "y";

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
    hardware =
      let
        mac80211 =  pkgs.mac80211.override {
          drivers = ["mac80211_hwsim"];
          klibBuild = config.system.outputs.kernel.modulesupport;
        };
        inherit (pkgs.liminix.networking) interface;
      in {
        defaultOutput = "vmroot";
        flash.eraseBlockSize = "65536"; # c.f. pkgs/mips-vm/mips-vm.sh
        networkInterfaces = {
          lan = interface { device = "eth0"; };
          wan = interface { device = "eth1"; };

          wlan_24 = interface {
            device = "wlan0";
            dependencies = [ mac80211 ];
          };
        };
      };

  };
}
