{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) dropbear;
  inherit (pkgs.liminix.services) longrun;
in
{
  imports = [
    ../../vanilla-configuration.nix
    ../../modules/outputs/jffs2.nix
  ];
  config = {
    services.sshd = longrun {
      name = "sshd";
      run = ''
        mkdir -p /run/dropbear
        ${dropbear}/bin/dropbear -E -P /run/dropbear.pid -R -F
      '';
    };

    users.root = {
      passwd = lib.mkForce "$6$GYDbeLSyoIdgDdZW$EXlz4oI7Jz1igSYd4cxwcWR4lqEc5AWdGWuPuBarQeUskFQsBCpPc0GgIPPDl1k7SgrnC82JzSWxvx5o0bvmx/";
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./id.pub)
      ];
    };

    rootfsType = "jffs2";
  };
}
