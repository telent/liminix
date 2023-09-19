{
  qemu
, socat
, ubootQemuAarch64
, writeShellScriptBin
, symlinkJoin
, lib
}: let
  mips-vm = writeShellScriptBin "mips-vm" ''
     export PATH="${lib.makeBinPath [qemu]}:$PATH"
     export UBOOT=${ubootQemuAarch64}/u-boot.bin
     ${builtins.readFile ./mips-vm.sh}
  '';
  connect = writeShellScriptBin "connect-vm" ''
    export PATH="${lib.makeBinPath [socat]}:$PATH"
    socat -,raw,echo=0,icanon=0,isig=0,icrnl=0,escape=0x0f unix-connect:$1
  '';
in symlinkJoin {
  name = "mips-vm";
  paths = [ mips-vm connect ];
}
