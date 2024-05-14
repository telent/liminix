{ config, ... }:
{
  config = {
    kernel.config = {
      USB_NET_HUAWEI_CDC_NCM = "y";
      USB_USBNET = "y";
      USB_SERIAL = "y";
      USB_SERIAL_OPTION = "y";
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
  
