{
  liminix
, nixpkgs
}:
let img = (import liminix {
      device = import "${liminix}/devices/qemu/";
      liminix-config = ./configuration.nix;
    }).outputs.vmroot;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    expect
    socat
    e2fsprogs
    util-linux # for sfdisk, fallocate
  ] ;
} ''
mkdir vm
dd if=/dev/zero of=./vm/stick.e2fs bs=1M count=32
mkfs.ext2 -L backup-disk ./vm/stick.e2fs
cat <(dd if=/dev/zero bs=512 count=4)  ./vm/stick.e2fs > ./vm/stick.img
echo '4,-,L,*' | sfdisk ./vm/stick.img

${img}/run.sh  --background ./vm --flag -device --flag usb-ehci,id=xhci --flag -drive  --flag if=none,id=usbstick,format=raw,file=$(pwd)/vm/stick.img
expect ${./script.expect} | tee $out
''
