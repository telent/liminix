{
  liminix
, nixpkgs
}:
let img = (import liminix {
      device = import "${liminix}/devices/qemu/";
      liminix-config = ./configuration.nix;
    }).outputs.default;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
    inherit (pkgs.pkgsBuildBuild)  mips-vm;
in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    expect
    mips-vm
    socat
  ] ;
} ''
killpid(){
  if test -e $1 && test -d /proc/`cat $1` ; then
    pid=$(cat $1)
    kill $pid
  fi
}

cleanup(){
  killpid ./vm/pid
}
trap cleanup EXIT
fatal(){
    err=$?
    echo "FAIL: command $(eval echo $BASH_COMMAND) exited with code $err"
    exit $err
}
trap fatal ERR

mkdir vm
mips-vm --background ./vm ${img}/vmlinux ${img}/squashfs
expect ${./wait-for-wlan.expect} |tee output && mv output $out
''
