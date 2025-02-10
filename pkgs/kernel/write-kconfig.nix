{
  lib,
  writeText,
}:
name: config:
writeText name (
  builtins.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: value: (if value == "n" then "# CONFIG_${name} is not set" else "CONFIG_${name}=${value}")
    ) config
  )
)
