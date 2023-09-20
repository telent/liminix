{
  liminix
, nixpkgs
}:
let img = (import liminix {
      device = import "${liminix}/devices/qemu/";
      liminix-config = ./configuration.nix;
    }).outputs.vmroot;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
    inherit (pkgs.pkgsBuildBuild) routeros run-liminix-vm;
in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    run-liminix-vm
    expect
    socat
  ] ;
} ''
mkdir vm
run-liminix-vm --background ./vm ${img}/vmlinux ${img}/rootfs
expect ${./script.expect} >$out
''
