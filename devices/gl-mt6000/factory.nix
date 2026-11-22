{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.system.outputs) dtb kernel rootfs;
  fit = pkgs.liminix.builders.uimage {
    inherit kernel dtb;
    inherit (config.hardware) loadAddress entryPoint alignment;
    inherit (config.boot) imageFormat commandLineDtbNode;
    commandLine = lib.concatStringsSep " " (
      builtins.filter (arg: !(lib.hasPrefix "root=" arg)) config.boot.commandLine
      ++ [
        # https://github.com/openwrt/openwrt/blob/8303e9b2a004a6c3754aaa1edb32cfc7c0cfe55b/target/linux/mediatek/dts/mt7986a-glinet-gl-mt6000.dts#L25
        "root=PARTLABEL=rootfs"
        "rootwait"
      ]
    );
  };
in
{
  options.system.outputs.factory = lib.mkOption {
    type = lib.types.package;
    description = "GL-MT6000 eMMC factory payload with a FIT kernel and squashfs.";
  };

  config.system.outputs.factory =
    assert config.rootfsType == "squashfs";
    pkgs.runCommand "gl-mt6000-factory.bin" { } ''
      # OpenWrt's GL-MT6000 factory layout reserves 32 MiB for the kernel.
      # https://github.com/openwrt/openwrt/blob/8303e9b2a004a6c3754aaa1edb32cfc7c0cfe55b/target/linux/mediatek/image/filogic.mk#L1751-L1764
      kernelSlotBytes=$((32 * 1024 * 1024))
      test "$(stat -Lc %s ${fit})" -le "$kernelSlotBytes"
      cp ${fit} "$out"
      chmod u+w "$out"
      truncate -s "$kernelSlotBytes" "$out"
      cat ${rootfs} >> "$out"
    '';
}
