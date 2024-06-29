# support for USB block devices and the common filesystems
# they're likely to provide

{ config, ... }:
{
  kernel = {
    config = {
      USB = "y";
      USB_EHCI_HCD = "y";
      USB_EHCI_HCD_PLATFORM = "y";
      USB_OHCI_HCD = "y";
      USB_OHCI_HCD_PLATFORM = "y";
      USB_SUPPORT = "y";
      USB_COMMON = "y";
      USB_STORAGE = "y";
      USB_STORAGE_DEBUG = "n";
      USB_UAS = "y";
      USB_ANNOUNCE_NEW_DEVICES = "y";
      SCSI = "y";
      BLK_DEV_SD = "y";
      USB_PRINTER = "y";
      MSDOS_PARTITION = "y";
      EFI_PARTITION = "y";
      EXT4_FS = "y";
      EXT4_USE_FOR_EXT2 = "y";
      FS_ENCRYPTION = "y";


    };
  };
}
