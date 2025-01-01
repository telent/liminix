{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf;
  o = config.system.outputs;
  inherit (pkgs) runCommand;
  inherit (lib) mkOption types;
  inherit (pkgs.buildPackages) min-copy-closure;
in
{
  imports = [ ../system-configuration.nix ];
  options.system.outputs.updater = mkOption {
    type = types.package;
    description = ''
      updater
      ******

      For configurations with a writable filesystem, create a shell
      script that runs on the build system and updates the device
      over the network to the new configuration
    '';
  };

  config.system.outputs.updater =
    runCommand "buildUpdater" { } ''
      mkdir -p $out/bin $out/etc
      cp ${o.kernel.config} $out/etc/kconfig
      substitute ${./update.sh} $out/bin/update.sh \
         --subst-var-by toplevel ${o.systemConfiguration} \
         --subst-var-by min_copy_closure ${min-copy-closure}
      chmod +x  $out/bin/update.sh
    '';
}
