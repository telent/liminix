{
  config
, pkgs
, lib
, ...
}:
let
  inherit (pkgs) liminix;
  inherit (lib) mkIf;
in
{
  config = mkIf (config.rootfsType == "squashfs") {
    system.outputs.rootfs =
      liminix.builders.squashfs config.filesystem.contents;
  };
}
