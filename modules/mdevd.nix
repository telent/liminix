{ config, pkgs, lib, ...} :
let inherit (pkgs.liminix.services) oneshot longrun;
in {
  config = {
    services = rec {
      mdevd = longrun {
        name = "mdevd";
        notification-fd = 3;
        run = "${pkgs.mdevd}/bin/mdevd -D 3 -b 200000 -O4";
      };
      devout = longrun {
        name = "devout";
        notification-fd = 10;
        run = "${pkgs.devout}/bin/devout /run/devout.sock 4";
      };
      mdevd-coldplug = oneshot {
        name ="mdev-coldplug";
        up = "${pkgs.mdevd}/bin/mdevd-coldplug -O 4";
        dependencies = [devout];
      };
    };
  };
}
