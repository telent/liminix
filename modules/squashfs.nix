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
    outputs = rec {
      rootfs = liminix.builders.squashfs config.filesystem.contents;
    };
  };
}
