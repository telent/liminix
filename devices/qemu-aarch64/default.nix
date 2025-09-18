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

== QEMU Aarch64

This target produces an image for the
https://www.qemu.org/docs/master/system/arm/virt.html[QEMU "virt"
platform] using a 64 bit CPU type.

ARM targets differ from MIPS in that the kernel format expected by QEMU
is an "Image" (raw binary file) rather than an ELF file, but this is
taken care of by `+run.sh+`. Check the documentation for the `+qemu+`
target for more information.
  '';

  # this device is described by the "qemu" device
  installer = "vmroot";

  module =
    { config, lim, ... }:
    {
      imports = [
        ../../modules/arch/aarch64.nix
        ../families/qemu.nix
      ];
      kernel = {
        config = {
          VIRTUALIZATION = "y";
          PCI_HOST_GENERIC = "y";

          SERIAL_AMBA_PL011 = "y";
          SERIAL_AMBA_PL011_CONSOLE = "y";
        };
      };
      boot.commandLine = [
        "console=ttyAMA0,38400"
      ];
      hardware =
        let
          addr = lim.parseInt "0x40010000";
        in
        {
          loadAddress = addr;
          entryPoint = addr;
        };
    };
}
