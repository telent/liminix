{
  device ? (import devices/gl-ar750.nix)
, phram ? false
}:

let
  overlay = import ./overlay.nix;
  nixpkgs = import <nixpkgs> (device.system // {overlays = [overlay device.overlay]; });
  inherit (nixpkgs) callPackage writeText liminix fetchFromGitHub;
  inherit (nixpkgs.lib) concatStringsSep;
  config = (import ./merge-modules.nix) [
    ./modules/base.nix
    ({ lib, ... } : { config = { inherit (device) kernel; }; })
    <liminix-config>
    ./modules/s6
    ./modules/users.nix
    (if phram then  ./modules/phram.nix else (args: {}))
  ] nixpkgs;
  squashfs = liminix.builders.squashfs config.filesystem.contents;
  kernel = callPackage ./kernel {
    inherit (config.kernel) config checkedConfig;
  };

  outputs = rec {
    inherit squashfs kernel;
    dtb =  kernel.dtb {
      dts = "qca9531_glinet_gl-ar750.dts";

    };
    uimage = kernel.uimage {
      commandLine = concatStringsSep " " config.boot.commandLine;
      inherit (device.boot) loadAddress entryPoint;
      inherit (kernel) vmlinux;
      inherit dtb;
    };
    combined-image = nixpkgs.runCommand "firmware.bin" {
      nativeBuildInputs = [ nixpkgs.buildPackages.ubootTools ];
    } ''
      mkdir $out
      dd if=${uimage} of=$out/firmware.bin bs=128k conv=sync
      dd if=${squashfs} of=$out/firmware.bin bs=128k conv=sync,nocreat,notrunc oflag=append
    '';
    boot-scr =
      let
        inherit (nixpkgs.lib.trivial) toHexString;
        uimageStart = 10485760; # 0xa00000
        squashfsStart = uimageStart + 4 * 1024 * 1024;
        squashfsSize = 8;
        cmd = "mtdparts=phram0:${toString squashfsSize}M(nix) phram.phram=phram0,0x${toHexString squashfsStart},${toString squashfsSize}Mi memmap=${toString squashfsSize}M\$0x${toHexString squashfsStart} root=1f00";
      in
        nixpkgs.buildPackages.writeScript "firmware.bin" ''
          setenv serverip 192.168.8.148
          setenv ipaddr 192.168.8.251
          setenv bootargs '${concatStringsSep " " config.boot.commandLine} ${cmd}'
          tftp 0x8${toHexString uimageStart} result/uimage ; tftp 0x8${toHexString squashfsStart} result/squashfs
          bootm 0x${toHexString uimageStart}
        '';

    directory = nixpkgs.runCommand "liminix" {} (''
      mkdir $out
      cd $out
      ln -s ${squashfs} squashfs
      ln -s ${kernel.vmlinux} vmlinux
      ln -s ${manifest} manifest
      ln -s ${kernel.vmlinux.modulesupport} build
    '' +
    (if device ? boot then ''
      ln -s ${uimage} uimage
      ${if phram then "ln -s ${boot-scr} boot.scr" else ""}
      ln -s ${boot-scr} flash.scr
    '' else ""));
    # this exists so that you can run "nix-store -q --tree" on it and find
    # out what's in the image, which is nice if it's unexpectedly huge
    manifest = writeText "manifest.json" (builtins.toJSON config.filesystem.contents);
    tftpd = nixpkgs.buildPackages.tufted;
  };
in {
  outputs = outputs // { default = outputs.${device.outputs.default}; };

  # this is just here as a convenience, so that we can get a
  # cross-compiling nix-shell for any package we're customizing
  inherit (nixpkgs) pkgs;
}
