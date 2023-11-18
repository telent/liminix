# This "device" generates images that can be used with the QEMU
# emulator. The default output is a directory containing separate
# kernel ("Image" format) and root filesystem (squashfs or jffs2)
# images
{
  system = {
    crossSystem = {
      config = "aarch64-unknown-linux-musl";
    };
  };

  description = ''
    QEMU Aarch64
    ************

    This target produces an image for
    the `QEMU "virt" platform <https://www.qemu.org/docs/master/system/arm/virt.html>`_ using a 64 bit CPU type.

    ARM targets differ from MIPS in that the kernel format expected
    by QEMU is an "Image" (raw binary file) rather than an ELF
    file, but this is taken care of by :command:`run.sh`. Check the
    documentation for the :ref:`QEMU` (MIPS) target for more information.

  '';

  # this device is described by the "qemu" device
  installer = "vmroot";

  module = {pkgs, config, lim, ... }: {
    imports = [ ../../modules/arch/aarch64.nix ];
    kernel = {
      src = pkgs.pkgsBuildBuild.fetchurl {
        name = "linux.tar.gz";
        url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
        hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
      };
      config = {
        VIRTUALIZATION = "y";
        PCI_HOST_GENERIC="y";

        MTD = "y";
        MTD_BLOCK = "y";
        MTD_CMDLINE_PARTS = "y";
        MTD_PHRAM = "y";

        VIRTIO_MENU = "y";
        PCI = "y";
        VIRTIO_PCI = "y";
        BLOCK = "y";
        VIRTIO_BLK = "y";
        VIRTIO_NET = "y";

        SERIAL_AMBA_PL011 = "y";
        SERIAL_AMBA_PL011_CONSOLE = "y";
      };
    };
    boot.commandLine = [
      "console=ttyAMA0,38400"
    ];
    hardware =
      let
        mac80211 =  pkgs.mac80211.override {
          drivers = ["mac80211_hwsim"];
          klibBuild = config.system.outputs.kernel.modulesupport;
        };
      in {
        defaultOutput = "vmroot";
        loadAddress = lim.parseInt "0x0";
        entryPoint = lim.parseInt "0x0";
        rootDevice = "/dev/mtdblock0";

        flash.eraseBlockSize = 65536; # c.f. pkgs/mips-vm/mips-vm.sh
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
