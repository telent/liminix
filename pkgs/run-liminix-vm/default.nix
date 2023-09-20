{
  qemu
, socat
, writeShellScriptBin
, symlinkJoin
, lib
}: let
  run-liminix-vm = writeShellScriptBin "run-liminix-vm" ''
     export PATH="${lib.makeBinPath [qemu]}:$PATH"
     ${builtins.readFile ./run-liminix-vm.sh}
  '';
  connect = writeShellScriptBin "connect-vm" ''
    export PATH="${lib.makeBinPath [socat]}:$PATH"
    socat -,raw,echo=0,icanon=0,isig=0,icrnl=0,escape=0x0f unix-connect:$1
  '';
in symlinkJoin {
  name = "run-liminix-vm";
  paths = [ run-liminix-vm connect ];
}
