# This "device" generates images that can be used with the QEMU
# emulator. The default output is a directory containing separate
# kernel (uncompressed vmlinux) and initrd (squashfs) images
{
  system = {
    crossSystem = {
      config = "aarch64-unknown-linux-musl";
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
        CPU_LITTLE_ENDIAN= "y";
        CPU_BIG_ENDIAN= "n";

        VIRTUALIZATION = "y";
        PCI_HOST_GENERIC="y";

        MTD = "y";
        MTD_BLOCK2MTD = "y";
        MTD_BLKDEVS = "y";
        MTD_BLOCK = "y";

        VIRTIO_MENU = "y";
        PCI = "y";
        VIRTIO_PCI = "y";
        BLOCK = "y";
        VIRTIO_BLK = "y";
        NETDEVICES = "y";
        VIRTIO_NET = "y";

        # https://stackoverflow.com/a/68340492
        CMDLINE="\"earlycon=smh console=ttyAMA0\"";
        CMDLINE_FROM_BOOTLOADER = "y";

        SERIAL_EARLYCON_ARM_SEMIHOST = "y"; # earlycon=smh
        SERIAL_AMBA_PL011 = "y";
        SERIAL_AMBA_PL011_CONSOLE = "y";
      };
    };
    hardware =
      let
        mac80211 =  pkgs.mac80211.override {
          drivers = ["mac80211_hwsim"];
          klibBuild = config.system.outputs.kernel.modulesupport;
        };
      in {
        defaultOutput = "vmroot";
        loadAddress = "0x0";
        entryPoint  = "0x0";
        dts.src = ./empty.dts;
        rootDevice = "/dev/mtd1";

        flash.eraseBlockSize = "65536"; # c.f. pkgs/mips-vm/mips-vm.sh
        networkInterfaces =
          let inherit (config.system.service.network) link;
          in {
            wan = link.build { ifname = "eth0"; };
            lan = link.build { ifname = "eth1"; };

            wlan_24 = link.build {
              ifname = "wlan0";
              dependencies = [ mac80211 ];
            };
          };
      };

  };
}
