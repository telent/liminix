{ config, pkgs, lib, ... }:
let
  cfg = config.bordervm;
  inherit (lib) mkOption mdDoc types;
in {
  options.bordervm = {
    l2tp = {
      host = mkOption {
        description = mdDoc ''
          Hostname or IP address of an L2TP LNS that this VM
          will connect to when it receives a PPPoE connection request
        '';
        type = types.str;
        example = "l2tp.example.org";
      };
      port = mkOption {
        description = mdDoc ''
          Port number, if non-standard, of the LNS.
        '';
        type = types.int;
        default = 1701;
      };
    };
    ethernet = {
      pciId = mkOption {
        description = ''
          Host PCI ID (as shown by `lspci`) of the ethernet adaptor
          to be used by the VM. This uses VFIO and requires setup
          on the emulation host before it will work!
        '';
        type = types.str;
        example = "04:00.0";
      };
    };
  };
  imports = [
    <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
  ];
  config = {
    boot.kernelParams = [
      "loglevel=9"
    ];
    systemd.services.pppoe =
      let conf = pkgs.writeText "kpppoed.toml"
        ''
      interface_name = "eth1"
      services = [ "myservice" ]
      lns_ipaddr = "${cfg.l2tp.host}:${builtins.toString cfg.l2tp.port}"
      ac_name = "kpppoed-1.0"
    '';
      in  {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
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
          "-device vfio-pci,host=${cfg.ethernet.pciId}"
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
  };
}
