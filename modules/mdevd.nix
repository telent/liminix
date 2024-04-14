{ config, pkgs, lib, ...} :
let inherit (pkgs.liminix.services) oneshot longrun bundle target;
in {
  config = {
    services = rec {
      mdevd = longrun {
        name = "mdevd";
        notification-fd = 3;
        run = "${pkgs.mdevd}/bin/mdevd -D 3 -b 200000 -O4";
      };
      mdevd-coldplug = oneshot {
        name ="mdev-coldplug";
        up = "${pkgs.mdevd}/bin/mdevd-coldplug";
      };
    };
  };
}
