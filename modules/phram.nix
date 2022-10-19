{
  config
, ...
}:
{
  config = {
    kernel = {
      config = {
        MTD = "y";
        MTD_PHRAM = "y";
        MTD_CMDLINE_PARTS = "y";

        # one or more of the following is required to get from
        # VFS: Cannot open root device "1f00" or unknown-block(31,0): error -6
        # to
        # VFS: Mounted root (squashfs filesystem) readonly on device 31:0.
        MTD_OF_PARTS = "y";
        PARTITION_ADVANCED = "y";
        MSDOS_PARTITION = "y";
        EFI_PARTITION = "y";
        MTD_BLKDEVS = "y";
        MTD_BLOCK = "y";

        # CONFIG_MTD_MTDRAM=m         c'est quoi?
      };

    };
  };
}
