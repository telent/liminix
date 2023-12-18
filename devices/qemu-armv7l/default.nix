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
  description = ''
    QEMU ARM v7
    ***********

    This target produces an image for
    the `QEMU "virt" platform <https://www.qemu.org/docs/master/system/arm/virt.html>`_ using a 32 bit CPU type.

    ARM targets differ from MIPS in that the kernel format expected
    by QEMU is an "Image" (raw binary file) rather than an ELF
    file, but this is taken care of by :command:`run.sh`. Check the
    documentation for the :ref:`QEMU` (MIPS) target for more information.
  '';
  installer = "vmroot";

  module = {pkgs, config, lim, ... }: {
    imports = [
      ../../modules/arch/arm.nix
      ../families/qemu.nix
    ];
    kernel = {
      config = {
        PCI_HOST_GENERIC = "y";
        ARCH_VIRT = "y";

        VFP = "y";
        NEON = "y";
        AEABI = "y";

        SERIAL_AMBA_PL011 = "y";
        SERIAL_AMBA_PL011_CONSOLE = "y";
      };
    };
    boot.commandLine = [
      "console=ttyAMA0"
    ];
    hardware = let addr = lim.parseInt "0x40008000"; in {
      loadAddress = addr;
      entryPoint = addr;
    };
  };
}
