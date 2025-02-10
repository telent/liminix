{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.liminix.services) longrun;
in
{
  config.services.klogd = longrun {
    name = "klogd";
    run = ''
      echo "1 2 1 8"  > /proc/sys/kernel/printk
      cat /proc/kmsg
    '';
    finish = ''
      echo "8 4 1 8"  > /proc/sys/kernel/printk
    '';
  };
}
