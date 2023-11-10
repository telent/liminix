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
   ./ext4fs.nix
   ./firewall
   ./hardware.nix
   ./hostapd
   ./hostname.nix
   ./initramfs.nix
   ./jffs2.nix
   ./kernel.nix
   ./kexecboot.nix
   ./mount
   ./network
   ./ntp
   ./outputs.nix
   ./outputs/vmroot.nix
   ./outputs/ubimage.nix
   ./outputs/flashimage.nix
   ./ppp
   ./ramdisk.nix
   ./squashfs.nix
   ./ssh
   ./standard.nix
   ./tftpboot.nix
   ./ubifs.nix
   ./users.nix
   ./vlan
   ./watchdog
   ./wlan.nix
 ];
}
