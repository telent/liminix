{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
in
{
  options = {
    system.outputs = {
      vmroot = mkOption {
        type = types.package;
        description = ''
          vmroot
          ******

          This target is for use with the qemu, qemu-aarch64, qemu-armv7l
          devices. It generates an executable :file:`run.sh` which
          invokes QEMU. It connects the Liminix
          serial console and the `QEMU monitor  <https://www.qemu.org/docs/master/system/monitor.html>`_
          to stdin/stdout. Use ^P (not ^A) to switch between monitor and
          stdio.

          If you call :command:`run.sh` with ``--background
          /path/to/some/directory`` as the first parameter, it will
          fork into the background and open Unix sockets in that
          directory for console and monitor.  Use :command:`nix-shell
          --run connect-vm` to connect to either of these sockets, and
          ^O to disconnect.

          Liminix VMs are networked using QEMU socket networking. The
          default behaviour is to connect

          * multicast 230.0.0.1:1234 ("access") to eth0
          * multicast 230.0.0.1:1235 ("lan") to eth1

          Refer to :ref:`border-network-gateway` for details of how to
          start an emulated upstream on the "access" network that
          your Liminix device can talk to.
        '';
      };
    };
  };
  config = {
    system.outputs = rec {
      vmroot =
        let
          inherit (config.system.outputs) rootfs kernel manifest;
          cmdline = builtins.toJSON (concatStringsSep " " config.boot.commandLine);
          makeBootableImage = pkgs.runCommandCC "objcopy" {}
            (if pkgs.stdenv.hostPlatform.isAarch
             then "${pkgs.stdenv.cc.targetPrefix}objcopy -O binary -R .comment -S ${kernel} $out"
             else "cp ${kernel} $out");
          phram_address = lib.toHexString (config.hardware.ram.startAddress + 256 * 1024 * 1024);
        in pkgs.runCommand "vmroot" {} ''
          mkdir $out
          cd $out
          ln -s ${rootfs} rootfs
          ln -s ${kernel} vmlinux
          ln -s ${manifest} manifest
          ln -s ${kernel.headers} build
          echo ${cmdline} > commandline
          cat > run.sh << EOF
          #!${pkgs.runtimeShell}
          ${pkgs.pkgsBuildBuild.run-liminix-vm}/bin/run-liminix-vm --command-line ${builtins.toJSON cmdline} --arch ${pkgs.stdenv.hostPlatform.qemuArch} --phram-address 0x${phram_address} \$* ${makeBootableImage} ${config.system.outputs.rootfs}
          EOF
          chmod +x run.sh
       '';
    };
  };
}
