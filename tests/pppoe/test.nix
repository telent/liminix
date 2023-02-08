{
  liminix
, nixpkgs
}:
let img = (import liminix {
      device = import "${liminix}/devices/qemu/";
      liminix-config = ./configuration.nix;
    }).outputs.default;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
    ros = pkgs.pkgsBuildBuild.routeros;
    run-qemu = pkgs.writeShellScriptBin "run-qemu" ''
      export PATH="${pkgs.lib.makeBinPath [pkgs.qemu]}:$PATH"
      ${builtins.readFile ../../scripts/run-qemu.sh}
    '';

in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    python3Packages.scapy
    expect
    jq
    socat
    ros.routeros
    run-qemu
  ] ;
} ''
serverstatedir=$(mktemp -d -t routeros-XXXXXX)
# python scapy drags in matplotlib which doesn't enjoy running in
# a sandbox with no $HOME, hence this environment variable
export MPLCONFIGDIR=$(mktemp -d -t routeros-XXXXXX)

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

routeros $serverstatedir

run-qemu --background foo.sock ${img}/vmlinux ${img}/squashfs
expect ${./getaddress.expect}

set -o pipefail
response=$(python ${./test-dhcp-service.py})
echo "$response" | jq -e 'select((.router ==  "192.168.19.1") and (.server_id=="192.168.19.1"))'
echo $response > $out
''
