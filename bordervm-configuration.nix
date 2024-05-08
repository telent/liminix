{ config, pkgs, lib, ... }:
let
  cfg = config.bordervm;
  inherit (lib) mkOption mkEnableOption mdDoc types optional optionals;
in {
  options.bordervm = {
    keys = mkOption {
      type = types.listOf types.str;
      default = [];
    };
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
      pci = {
        enable = mkEnableOption "passthru PCI ethernet";
        id = mkOption {
          description = ''
            Host PCI ID (as shown by `lspci`) of the ethernet adaptor
            to be used by the VM. This uses VFIO and requires setup
            on the emulation host before it will work!
          '';
          type = types.str;
          example = "04:00.0";
        };
      };
      usb = {
        enable = mkEnableOption "passthru USB ethernet";
        vendor = mkOption {
          type = types.str;
          example = "0x0bda";
        };
        product = mkOption {
          type = types.str;
          example = "0x8153";
        };
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
    services.openssh.enable = true;
    services.dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings =  {
        # domain-needed = true;
        dhcp-range = [ "10.0.0.10,10.0.0.240" ];
        interface = "eth1";
      };
    };

    systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];


    virtualisation = {
      qemu = {
        networkingOptions = [];
        options = [] ++
          optional cfg.ethernet.pci.enable
            "-device vfio-pci,host=${cfg.ethernet.pci.id}" ++
          optionals cfg.ethernet.usb.enable [
            "-device usb-ehci,id=ehci"
            "-device usb-host,bus=ehci.0,vendorid=${cfg.ethernet.usb.vendor},productid=${cfg.ethernet.usb.product}"
          ] ++ [
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
    environment.systemPackages =
      let wireshark-nogui = pkgs.wireshark.override { withQt = false ; };
          in with pkgs; [
            tcpdump
            wireshark-nogui
            socat
            tufted
            iptables
            usbutils
            busybox
          ];
    security.sudo.wheelNeedsPassword = false;
    networking = {
      hostName = "border";
      firewall = { enable = false; };
      interfaces.eth1 = {
        useDHCP = false;
        ipv4.addresses = [ { address = "10.0.0.1"; prefixLength = 24;}];
      };
      nat = {
        enable = true;
        internalInterfaces = [ "eth1" ];
        externalInterface ="eth0";
      };
    };
    users.users.liminix = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel"];
      openssh.authorizedKeys.keys = cfg.keys;
    };
    services.getty.autologinUser = "liminix";
  };
}
