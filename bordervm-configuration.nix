{ config, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
  ];
  boot.kernelParams = [
    "loglevel=9"
  ];
  systemd.services.pppoe =
    let conf = pkgs.writeText "kpppoed.toml"
    ''
      interface_name = "eth0"
      services = [ "myservice" ]
      lns_ipaddr = "90.155.53.19"
      ac_name = "kpppoed-1.0"
    '';
    in  {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.go-l2tp}/bin/kpppoed -config ${conf}";
      };
    };
  systemd.services.tufted = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.tufted}/bin/tufted /home/liminix/liminix";
    };
  };
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  virtualisation = {
    qemu = {
      networkingOptions = [];
      options = [
        "-device vfio-pci,host=01:00.0"
        "-nographic"
        "-serial mon:stdio"
      ];
    };
    sharedDirectories = {
      liminix = {
        source = builtins.toString ./.;
        target = "/home/liminix/liminix";
      };
    };
  };
  environment.systemPackages = with pkgs; [
    tcpdump
    wireshark
    socat
    tufted
    iptables
  ];
  security.sudo.wheelNeedsPassword = false;
  networking = {
    hostName = "border";
    firewall = { enable = false; };
    interfaces.eth1 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "10.0.0.1"; prefixLength = 24;}];
    };
  };
  users.users.liminix = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel"];
  };
  services.getty.autologinUser = "liminix";
}
