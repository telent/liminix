{
  device
, liminix-config ? <liminix-config>
, nixpkgs ? <nixpkgs>
}:

let
  overlay = import ./overlay.nix;
  pkgs = import nixpkgs (device.system // {
    overlays = [overlay];
    config = {allowUnsupportedSystem = true; };
  });

  config = (import ./lib/merge-modules.nix) [
    ./modules/base.nix
    device.module
    liminix-config
    ./modules/s6
    ./modules/users.nix
    ./modules/outputs.nix
  ] pkgs;

  borderVm = ((import <nixpkgs/nixos>) {
    configuration =
      { config, ... }:
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
              ExecStart = "${pkgs.pkgsBuildBuild.go-l2tp}/bin/kpppoed -config ${conf}";
            };
          };
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
        environment.systemPackages = [ pkgs.pkgsBuildBuild.tufted ];
        security.sudo.wheelNeedsPassword = false;
        networking = {
          hostName = "border";
          firewall = { enable = false; };
        };
        users.users.liminix = {
          isNormalUser = true;
          uid = 1000;
          extraGroups = [ "wheel"];
        };
        services.getty.autologinUser = "liminix";
      };
  }).config.system;
in {
  outputs = config.outputs // {
    default = config.outputs.${config.device.defaultOutput};
  };

  # this is just here as a convenience, so that we can get a
  # cross-compiling nix-shell for any package we're customizing
  inherit pkgs;

  buildEnv = pkgs.mkShell {
    packages = with pkgs.pkgsBuildBuild; [
      tufted
      routeros.routeros
      routeros.ros-exec-script
      mips-vm
      borderVm.build.vm
      go-l2tp
    ];
  };
}
