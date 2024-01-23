{ config, pkgs, lib, ... } :
let
  inherit (pkgs) serviceFns;
  svc = config.system.service;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs.liminix.services) oneshot longrun bundle target;
  some-util-linux = pkgs.runCommand "some-util-linux" {} ''
    mkdir -p $out/bin
    cd ${pkgs.util-linux-small}/bin
    cp fdisk sfdisk mkswap $out/bin
  '';
in rec {
  imports = [
    ../modules/network
    ../modules/ssh
    ../modules/usb.nix
    ../modules/schnapps
    ../modules/outputs/mtdimage.nix
    ../modules/outputs/mbrimage.nix
    ../modules/outputs/tftpboot.nix
    ../modules/outputs/ubifs.nix
    ../modules/outputs/ubimage.nix
    ../modules/outputs/jffs2.nix
    ../modules/outputs/ext4fs.nix
  ];

  kernel.config = {
    BTRFS_FS = "y";
  };

  boot.tftp = {
    ipaddr = "10.0.0.8"; # my address
    serverip = "10.0.0.1"; # build machine or other tftp server
  };

  hostname = "recovery";

  services.dhcpc = svc.network.dhcp.client.build {
    interface = config.hardware.networkInterfaces.lan2;

    # don't start DHCP until the hostname is configured,
    # so it can identify itself to the DHCP server
    dependencies = [ config.services.hostname ];
  };

  services.sshd = svc.ssh.build { };

  services.defaultroute4 = svc.network.route.build {
    via = "$(output ${services.dhcpc} router)";
    target = "default";
    dependencies = [services.dhcpc];
  };
  services.resolvconf = oneshot rec {
    dependencies = [ services.dhcpc ];
    name = "resolvconf";
    up = ''
      . ${serviceFns}
      ( in_outputs ${name}
      for i in $(output ${services.dhcpc} dns); do
        echo "nameserver $i" > resolv.conf
      done
      )
    '';
  };
  filesystem = dir {
    etc = dir {
      "resolv.conf" = symlink "${services.resolvconf}/.outputs/resolv.conf";
    };
    mnt = dir {};
  };
  rootfsType = "squashfs";
  # sda is most likely correct for the boot-from-USB case. For tftp
  # it's overridden by the boot.scr anyway, so maybe it all works out
  hardware.rootDevice = "/dev/sda1";
  users.root = {
    # the password is "secret". Use mkpasswd -m sha512crypt to
    # create this hashed password string
    passwd = "$6$y7WZ5hM6l5nriLmo$5AJlmzQZ6WA.7uBC7S8L4o19ESR28Dg25v64/vDvvCN01Ms9QoHeGByj8lGlJ4/b.dbwR9Hq2KXurSnLigt1W1";
  };

  defaultProfile.packages = with pkgs; [
    e2fsprogs # ext4
    btrfs-progs
    mtdutils # mtd, jffs2, ubifs
    dtc      # you never know when you might need device tree stuff
    some-util-linux
    libubootenv # fw_{set,print}env
    pciutils
  ];
}
