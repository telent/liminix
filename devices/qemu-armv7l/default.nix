# This "device" generates images that can be used with the QEMU
# emulator. The default output is a directory containing separate
# kernel ("Image" format) and root filesystem (squashfs or jffs2)
# images
{
  system = {
    crossSystem = {
      config =  "armv7l-unknown-linux-musleabihf";
    };
  };

  # this device is described by the "qemu" device
  description = "";

  module = {pkgs, config, ... }: {
    imports = [ ../../modules/arch/arm.nix ];
    kernel = {
      src = pkgs.pkgsBuildBuild.fetchurl {
        name = "linux.tar.gz";
        url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
        hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
      };
      config = {
        PCI_HOST_GENERIC = "y";
        PCI = "y";
        ARCH_VIRT = "y";

        VFP = "y";
        NEON = "y";
        AEABI = "y";

        MTD = "y";
        MTD_BLOCK = "y";
        MTD_CMDLINE_PARTS = "y";
        MTD_PHRAM = "y";

        VIRTIO_MENU = "y";
        VIRTIO_PCI = "y";
        BLOCK = "y";
        VIRTIO_BLK = "y";
        VIRTIO_NET = "y";

        SERIAL_EARLYCON_ARM_SEMIHOST = "y"; # earlycon=smh
        SERIAL_AMBA_PL011 = "y";
        SERIAL_AMBA_PL011_CONSOLE = "y";
      };
    };
    boot.commandLine = [
      "console=ttyAMA0"
    ];
    hardware =
      let
        mac80211 =  pkgs.mac80211.override {
          drivers = ["mac80211_hwsim"];
          klibBuild = config.system.outputs.kernel.modulesupport;
        };
      in {
        defaultOutput = "vmroot";
        loadAddress = "0x00010000";
        entryPoint  = "0x00010000";
        rootDevice = "/dev/mtdblock0";

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
