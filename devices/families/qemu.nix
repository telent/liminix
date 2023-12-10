{ config, pkgs, ... }:
{
  imports = [
    ../../modules/outputs/jffs2.nix
  ];
  config = {
    kernel = {
      src = pkgs.pkgsBuildBuild.fetchurl {
        name = "linux.tar.gz";
        url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
        hash = "sha256-yhO2cXIeIgUxkSZf/4aAsF11uxyh+UUZu6D1h92vCD8=";
      };
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
    };
    hardware =
      let
        mac80211 =  pkgs.mac80211.override {
          drivers = ["mac80211_hwsim"];
          klibBuild = config.system.outputs.kernel.modulesupport;
        };
      in {
        defaultOutput = "vmroot";
        rootDevice = "/dev/mtdblock0";
        dts.src = null;
        flash.eraseBlockSize = 65536;
        networkInterfaces =
          let inherit (config.system.service.network) link;
          in {
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
