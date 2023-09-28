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

  description = ''
    QEMU
    ****

    This is not a hardware device. This target produces an image for
    QEMU, the "generic and open source machine emulator and
    virtualizer".

    Liminix can build QEMU for both MIPS (:code:`qemu` device) and Aarch64 (:code:`qemu-aarch64` device)

    MIPS QEMU emulates a "Malta" board, which was an ATX form factor
    evaluation board made by MIPS Technologies, but mostly in Liminix
    we use paravirtualized devices (Virtio) instead of emulating
    hardware. For Aarch64 we use the QEMU "virt" board.

    Building an image for QEMU results in a :file:`result/` directory
    containing ``run.sh`` ``vmlinux``, ``rootfs`` and possibly
    (architecture-dependent) ``Image``. To invoke the emulator,
    run ``run.sh``.

    The configuration includes two emulated "hardware" ethernet
    devices and the kernel :code:`mac80211_hwsim` module to
    provide an emulated wlan device. To read more about how
    to connect to this network, refer to :ref:`qemu-networking`
    in the Development manual.

  '';
  module = {pkgs, config, ... }: {
    imports = [ ../../modules/arch/mipseb.nix ];
    kernel = {
      src = pkgs.pkgsBuildBuild.fetchurl {
        name = "linux.tar.gz";
        url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
        hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
      };
      config = {
        MIPS_MALTA= "y";
        CPU_MIPS32_R2= "y";

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
      in {
        defaultOutput = "vmroot";
        rootDevice = "/dev/mtdblock0";
        flash.eraseBlockSize = "65536"; # c.f. pkgs/run-liminix-vm/run-liminix-vm.sh
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
