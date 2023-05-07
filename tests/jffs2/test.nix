{
  liminix
, nixpkgs
}:
let img = (import liminix {
      device = import "${liminix}/devices/qemu/";
      liminix-config = ./configuration.nix;
    }).outputs.vmroot;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
    inherit (pkgs.pkgsBuildBuild) routeros mips-vm;
in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    mips-vm
    expect
    socat
  ] ;
} ''
mkdir vm
mips-vm --background ./vm ${img}/vmlinux ${img}/rootfs
expect ${./script.expect} >$out
''
