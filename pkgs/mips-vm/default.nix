{
  qemu
, writeShellScriptBin
, stdenv
, lib
}:
writeShellScriptBin "mips-vm"
  ''
     export PATH="${lib.makeBinPath [qemu]}:$PATH"
     ${builtins.readFile ./mips-vm.sh}
  ''
