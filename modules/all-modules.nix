# Import all of the modules, used in the documentation generator. Not
# currently expected to work in an actual configuration, but it would
# be nice if it did.

{
  imports = [
   ./base.nix
   ./bridge
   ./busybox.nix
   ./dhcp6c
   ./dnsmasq
   ./firewall
   ./hardware.nix
   ./hostapd
   ./hostname.nix
   ./kernel
   ./mdevd.nix
   ./mount
   ./network
   ./ntp
   ./outputs.nix
   ./outputs/ext4fs.nix
   ./outputs/initramfs.nix
   ./outputs/jffs2.nix
   ./outputs/mtdimage.nix
   ./outputs/tftpboot.nix
   ./outputs/tftpbootubi.nix
   ./outputs/ubifs.nix
   ./outputs/ubimage.nix
   ./outputs/vmroot.nix
   ./ppp
   ./ramdisk.nix
   ./ssh
   ./users.nix
   ./vlan
   ./watchdog
   ./wlan.nix
 ];
}
