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
   ./outputs/ext4fs.nix
   ./firewall
   ./hardware.nix
   ./hostapd
   ./hostname.nix
   ./outputs/initramfs.nix
   ./outputs/jffs2.nix
   ./kernel
   ./outputs/kexecboot.nix
   ./mount
   ./network
   ./ntp
   ./outputs.nix
   ./outputs/vmroot.nix
   ./outputs/ubimage.nix
   ./outputs/mtdimage.nix
   ./ppp
   ./ramdisk.nix
   ./squashfs.nix
   ./ssh
   ./outputs/tftpboot.nix
   ./outputs/ubifs.nix
   ./ubifs.nix
   ./ubinize.nix
   ./users.nix
   ./vlan
   ./watchdog
   ./wlan.nix
 ];
}
