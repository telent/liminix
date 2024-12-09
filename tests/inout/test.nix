let img = (import <liminix> {
      device = import <liminix/devices/qemu>;
      liminix-config = ./configuration.nix;
    }).outputs.vmroot;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    expect
    socat
    e2fsprogs
    util-linux # for sfdisk, fallocate
    parted
  ] ;
} ''
mkdir vm
dd if=/dev/zero of=./vm/stick.e2fs bs=1M count=32
mkfs.ext2 -L backup-disk ./vm/stick.e2fs
dd if=/dev/zero of=./vm/stick.img bs=1M count=38
dd if=./vm/stick.e2fs of=./vm/stick.img bs=512 seek=34 conv=notrunc
parted -s ./vm/stick.img -- mklabel gpt mkpart backup-disk ext2 34s -0M
sync
cp  ./vm/stick.img  ./vm/stick.img.orig

{


${img}/run.sh  --background ./vm --flag -device --flag usb-ehci,id=xhci --flag -drive  --flag if=none,id=usbstick,format=raw,file=$(pwd)/vm/stick.img
expect ${./script.expect} late
kill $(cat ./vm/pid)

cp  ./vm/stick.img.orig ./vm/stick.img
${img}/run.sh  --background ./vm --flag -device --flag usb-ehci,id=xhci --flag -drive  --flag if=none,id=usbstick,format=raw,file=$(pwd)/vm/stick.img
expect ${./script.expect} early

} | tee  $out

''
