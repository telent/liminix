{ config, pkgs, lib, ... }:
let
  inherit (pkgs.liminix.services) oneshot;
  svc = config.system.service;
in {
  config = {
    kernel.config = {
      USB_NET_HUAWEI_CDC_NCM = "y";
      USB_USBNET = "y";
      USB_SERIAL = "y";
      USB_SERIAL_OPTION = "y";
    };

    # https://www.0xf8.org/2017/01/flashing-a-huawei-e3372h-4g-lte-stick-from-hilink-to-stick-mode/

    services.wwan = let
      chat = lib.escapeShellArgs [
        "" "AT"
        "OK" "ATZ"
        "OK" "AT+CGDCONT=1,\"IP\",\"data.uk\""
        "OK"  "AT+CGACT=1,1"
        # caret is special to chat, so needs escaping in AT commands
        "OK"  "AT\\^AUTHDATA=1,2,\"1p\",\"one2one\",\"user\""
        "OK" "AT\\^NDISDUP=1,1" # ,\"data.uk\",\"user\",\"one2one\",2"
      ];
      modemConfig = oneshot {
        name = "modem-configure";
        up = ''
          sleep 2
          ${pkgs.usb-modeswitch}/bin/usb_modeswitch -v 12d1 -p 14fe --huawei-new-mode
          sleep 5
          ${pkgs.ppp}/bin/chat -s -v ${chat}  0<>/dev/ttyUSB0 1>&0
        '';
        down = "chat -v '' ATZ OK  </dev/ttyUSB0 >&0";
      };
    in svc.network.link.build {
      ifname = "wwan0";
      dependencies = [ modemConfig ];
    };

    # an ncm ethernet adaptor does
    # * usb modeswitch
    # * AT commands
    # and then behaves like a link.

    # we could identify by vid:pid but that's a bit awkward
    # if there's more than one present.  IMEI?

    # https://stackoverflow.com/questions/5477882/how-to-i-detect-whether-a-tty-belonging-to-a-gsm-3g-modem-is-a-data-or-control-p
  };
}
