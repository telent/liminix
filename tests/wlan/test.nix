{
  liminix
, nixpkgs
}:
let img = (import liminix {
      device = import "${liminix}/devices/qemu/";
      liminix-config = ./configuration.nix;
    }).outputs.default;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
    inherit (pkgs.pkgsBuildBuild)  run-liminix-vm;
in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    expect
    run-liminix-vm
    socat
  ] ;
} ''
. ${../test-helpers.sh}

mkdir vm
run-liminix-vm --background ./vm ${img}/vmlinux ${img}/rootfs
expect ${./wait-for-wlan.expect} |tee output && mv output $out
''
