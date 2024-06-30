{ ... }:
{
  bordervm = {
    # ethernet.pci = { id = "01:00.0"; enable = true; };
    ethernet.usb = {
      vendor = "0x0bda";
      product = "0x8153";
      enable = true;
    };
    l2tp = {
      host = "l2tp.aa.net.uk";
    };
  };
}
