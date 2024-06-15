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
        run = "exec ${pkgs.devout}/bin/devout /run/devout.sock 4";
      };
      coldplug = oneshot {
        name ="coldplug";
        # would love to know what mdevd-coldplug/udevadm trigger does
        # that this doesn't
        up = ''
          for i in $(find /sys -name uevent); do ( echo change > $i ) ; done
        '';
        dependencies = [devout mdevd];
      };
    };
  };
}
