{ config, pkgs, lib, ... } :
let
  inherit (pkgs) dropbear;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  inherit
    (pkgs.liminix.networking)
    address
    udhcpc
    interface
    route
  ;
in {
  imports = [
    ../../vanilla-configuration.nix
    ../../modules/squashfs.nix
    ../../modules/jffs2.nix
  ];
  config =  {
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

    # services.dhcpc =
    #   let iface =  config.hardware.networkInterfaces.lan;
    #   in (udhcpc iface {
    #     dependencies = [ config.services.hostname ];
    #   }) // { inherit (iface) device; };

    rootfsType = "jffs2";
    services.default = lib.mkForce (target {
      name = "default";
      contents = with config.services; [ loopback ntp defaultroute4 sshd dhcpv4 ];
    });
  };
}
