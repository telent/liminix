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
    QEMU MIPS
    *********

    This target produces an image for
    QEMU, the "generic and open source machine emulator and
    virtualizer".

    MIPS QEMU emulates a "Malta" board, which was an ATX form factor
    evaluation board made by MIPS Technologies, but mostly in Liminix
    we use paravirtualized devices (Virtio) instead of emulating
    hardware.

    Building an image for QEMU results in a :file:`result/` directory
    containing ``run.sh`` ``vmlinux``, and ``rootfs`` files. To invoke
    the emulator, run ``run.sh``.

    The configuration includes two emulated "hardware" ethernet
    devices and the kernel :code:`mac80211_hwsim` module to
    provide an emulated wlan device. To read more about how
    to connect to this network, refer to :ref:`qemu-networking`
    in the Development manual.

  '';
  module = { config, lib, lim, ... }: {
    imports = [
      ../../modules/arch/mipseb.nix
      ../families/qemu.nix
    ];
    kernel = {
      config = {
        MIPS_MALTA= "y";
        CPU_MIPS32_R2= "y";

        POWER_RESET = "y";
        POWER_RESET_SYSCON = "y";

        SERIAL_8250= "y";
        SERIAL_8250_CONSOLE= "y";
      };
    };
    hardware =
      # from arch/mips/mti-malta/Platform:load-$(CONFIG_MIPS_MALTA)  += 0xffffffff80100000
      let addr = lim.parseInt "0x80100000";
      in {
        loadAddress = addr;
        entryPoint = addr;

        # Unlike the arm qemu targets, we need a static dts when
        # running u-boot-using tests, qemu dumpdtb command doesn't
        # work for this board. I am not at all sure this dts is
        # *correct* but it does at least boot
        dts = lib.mkForce {
          src = "${config.system.outputs.kernel.modulesupport}/arch/mips/boot/dts/mti/malta.dts";
          includes =  [
            "${config.system.outputs.kernel.modulesupport}/arch/mips/boot/dts/"
          ];
        };

      };
  };
}
