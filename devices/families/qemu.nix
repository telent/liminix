{ config, pkgs, ... }:
{
  imports = [
    ../../modules/outputs/jffs2.nix
  ];
  config = {
    kernel = {
      config = {
        MTD = "y";
        MTD_BLOCK = "y";
        MTD_CMDLINE_PARTS = "y";
        MTD_PHRAM = "y";

        VIRTIO_MENU = "y";
        PCI = "y";
        VIRTIO_PCI = "y";
        BLOCK = "y";
        VIRTIO_BLK = "y";
        VIRTIO_NET = "y";
      };
      conditionalConfig = {
        WLAN = {
          MAC80211_HWSIM = "m";
        };
      };
    };
    hardware =
      let
        mac80211 = pkgs.kmodloader.override {
          inherit (config.system.outputs) kernel;
          targets = [ "mac80211_hwsim" ];
        };
      in
      {
        defaultOutput = "vmroot";
        rootDevice = "/dev/mtdblock0";
        dts.src = pkgs.lib.mkDefault null;
        flash.eraseBlockSize = 65536;
        networkInterfaces =
          let
            inherit (config.system.service.network) link;
          in
          {
            wan = link.build {
              devpath = "/devices/pci0000:00/0000:00:13.0/virtio0";
              ifname = "wan";
            };
            lan = link.build {
              devpath = "/devices/pci0000:00/0000:00:14.0/virtio1";
              ifname = "lan";
            };

            wlan_24 = link.build {
              ifname = "wlan0";
              dependencies = [ mac80211 ];
            };
          };
      };
  };
}
