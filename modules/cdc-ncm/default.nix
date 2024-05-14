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
        # Your usb modem thing might present as a tty that you run PPP
        # over, or as a network device ("ndis" or "ncm"). The latter
        # kind is to be preferred, at least in principle, because it's
        # faster.  This initialization sequence works for the Huawei
        # E3372, and took much swearing: the error messages are *awful*
        "" "AT"
        "OK" "ATZ"
        # create PDP context
        "OK" "AT+CGDCONT=1,\"IP\",\"data.uk\""
        # activate PDP context
        "OK"  "AT+CGACT=1,1"
        # setup username and password per requirements of sim provider.
        # (caret is special to chat, so needs escaping in AT commands)
        "OK"  "AT\\^AUTHDATA=1,2,\"1p\",\"one2one\",\"user\""
        # start the thing (I am choosing to read this as "NDIS DialUP")
        "OK" "AT\\^NDISDUP=1,1"
      ];
      modemConfig = oneshot {
        name = "modem-configure";
        # this is currently only going to work if there is one
        # modem only plugged in, it is plugged in already at boot,
        # and nothing else is providing a USB tty.
        # https://stackoverflow.com/questions/5477882/how-to-i-detect-whether-a-tty-belonging-to-a-gsm-3g-modem-is-a-data-or-control-p
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


  };
}
