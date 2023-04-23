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
serverstatedir=$(mktemp -d -t routeros-XXXXXX)

killpid(){
  if test -e $1 && test -d /proc/`cat $1` ; then
    pid=$(cat $1)
    kill $pid
  fi
}

cleanup(){
  killpid $serverstatedir/pid
  test -n "$MPLCONFIGDIR" && test -d "$MPLCONFIGDIR" && rm -rf "$MPLCONFIGDIR"
  killpid foo.pid
}
trap cleanup EXIT

fatal(){
  err=$?
  echo "FAIL: command $(eval echo $BASH_COMMAND) exited with code $err"
  exit $err
}
trap fatal ERR

mkdir vm
mips-vm --background ./vm ${img}/vmlinux ${img}/rootfs
expect ${./script.expect} >$out
''
