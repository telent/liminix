{ config, pkgs, ... }:
let
  svc = config.system.service;

in
rec {
  imports = [
    ../modules/network
    ../modules/ssh
    ../modules/vlan
  ];

  boot.tftp = {
    # IP addresses to use in the boot monitor when flashing/ booting
    # over TFTP. If you are flashing using the stock firmware's Web UI
    # then these dummy values are fine
    ipaddr = "192.0.2.115"; # my address
    serverip = "192.0.2.5"; # build machine or other tftp server
  };

  hostname = "hello";

  services.dhcpc = svc.network.dhcp.client.build {
    interface = config.hardware.networkInterfaces.lan;

    # don't start DHCP until the hostname is configured,
    # so it can identify itself to the DHCP server
    dependencies = [ config.services.hostname ];
  };

  services.sshd = svc.ssh.build { };

  users.root = {
    # the password is "secret". Use mkpasswd -m sha512crypt to
    # create this hashed password string
    passwd = "$6$y7WZ5hM6l5nriLmo$5AJlmzQZ6WA.7uBC7S8L4o19ESR28Dg25v64/vDvvCN01Ms9QoHeGByj8lGlJ4/b.dbwR9Hq2KXurSnLigt1W1";
  };

  defaultProfile.packages = with pkgs; [
    figlet
  ];
}
