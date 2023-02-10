{
  device
, liminix-config ? <liminix-config>
, phram ? false
, nixpkgs ? <nixpkgs>
}:

let
  overlay = import ./overlay.nix;
  pkgs = import nixpkgs (device.system // {
    overlays = [overlay];
    config = {allowUnsupportedSystem = true; };
  });
  inherit (pkgs) callPackage writeText liminix fetchFromGitHub;
  inherit (pkgs.lib) concatStringsSep;
  config = (import ./merge-modules.nix) [
    ./modules/base.nix
    device.module
    liminix-config
    ./modules/s6
    ./modules/users.nix
    (if phram then  ./modules/phram.nix else (args: {}))
  ] pkgs;
  squashfs = liminix.builders.squashfs config.filesystem.contents;

  openwrt = fetchFromGitHub {
    name = "openwrt-source";
    repo = "openwrt";
    owner = "openwrt";
    rev = "a5265497a4f6da158e95d6a450cb2cb6dc085cab";
    hash = "sha256-YYi4gkpLjbOK7bM2MGQjAyEBuXJ9JNXoz/JEmYf8xE8=";
  };

  outputs = rec {
    inherit squashfs;
    kernel = liminix.builders.kernel.override {
      inherit (config.kernel) config src extraPatchPhase;
    };
    dtb =  (callPackage ./kernel/dtb.nix {}) {
      dts = config.kernel.dts;
      includes = [
        "${openwrt}/target/linux/ath79/dts"
        "${kernel.headers}/include"
      ];
    };
    uimage = (callPackage ./kernel/uimage.nix {}) {
      commandLine = concatStringsSep " " config.boot.commandLine;
      inherit (config.device) loadAddress entryPoint;
      inherit kernel;
      inherit dtb;
    };
    combined-image = pkgs.runCommand "firmware.bin" {
      nativeBuildInputs = [ pkgs.buildPackages.ubootTools ];
    } ''
      mkdir $out
      dd if=${uimage} of=$out/firmware.bin bs=128k conv=sync
      dd if=${squashfs} of=$out/firmware.bin bs=128k conv=sync,nocreat,notrunc oflag=append
    '';
    boot-scr =
      let
        inherit (pkgs.lib.trivial) toHexString;
        uimageStart = 10485760; # 0xa00000
        squashfsStart = uimageStart + 4 * 1024 * 1024;
        squashfsSize = 8;
        cmd = "mtdparts=phram0:${toString squashfsSize}M(nix) phram.phram=phram0,0x${toHexString squashfsStart},${toString squashfsSize}Mi memmap=${toString squashfsSize}M\$0x${toHexString squashfsStart} root=1f00";
      in
        pkgs.buildPackages.writeScript "firmware.bin" ''
          setenv serverip 192.168.8.148
          setenv ipaddr 192.168.8.251
          setenv bootargs '${concatStringsSep " " config.boot.commandLine} ${cmd}'
          tftp 0x8${toHexString uimageStart} result/uimage ; tftp 0x8${toHexString squashfsStart} result/squashfs
          bootm 0x${toHexString uimageStart}
        '';

    directory = pkgs.runCommand "liminix" {} (''
      mkdir $out
      cd $out
      ln -s ${squashfs} squashfs
      ln -s ${kernel} vmlinux
      ln -s ${manifest} manifest
      ln -s ${kernel.headers} build
    '' +
    (if config.device.loadAddress != null  then
      ''
      ln -s {uimage} uimage
      ${if phram then "ln -s ${boot-scr} boot.scr" else ""}
      ln -s ${boot-scr} flash.scr
    '' else ""));
    # this exists so that you can run "nix-store -q --tree" on it and find
    # out what's in the image, which is nice if it's unexpectedly huge
    manifest = writeText "manifest.json" (builtins.toJSON config.filesystem.contents);
    tftpd = pkgs.buildPackages.tufted;
  };
in {
  outputs = outputs // { default = outputs.${config.device.defaultOutput}; };

  # this is just here as a convenience, so that we can get a
  # cross-compiling nix-shell for any package we're customizing
  inherit pkgs;

  buildEnv = pkgs.mkShell {
    packages = with pkgs.pkgsBuildBuild; [
      tufted
      routeros.routeros
      routeros.ros-exec-script
      mips-vm
    ];
  };
}
