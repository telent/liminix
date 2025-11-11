{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.pseudofile) dir symlink;
in
{
  options = {
    early = with types; {
      sysctl = mkOption {
        type = attrsOf anything;
        description = "sysctl definitions to set at early boot";
        example = {
          vm.overcommit_memory = 0;
          user.max_cgroup_namespaces = 62933;
          net.ipv6.route.gc_timeout = 60;
        };
      };
    };
  };
  config.filesystem = dir {
    etc =
      let
        sysctls = pkgs.writeAshScript "sysctls" { } ''
          cd /proc/sys
          ${pkgs.liminix.writeSysctls config.early.sysctl}
        '';
      in
      dir {
        "sysctl.sh" = symlink sysctls;
      };
  };
}
