{
  qemuLim,
  socat,
  writeShellScript,
  writeFennel,
  runCommand,
  fennel,
  lib,
  lua,
  pkgsBuildBuild,
}:
let
  writeFennel = pkgsBuildBuild.writeFennel.override { inherit lua; };
  run-liminix-vm = writeFennel "run-liminix-vm" {
    packages = [ qemuLim lua.pkgs.luaposix fennel ];
  } ./run-liminix-vm.fnl;
  connect = writeShellScript "connect-vm" ''
    export PATH="${lib.makeBinPath [ socat ]}:$PATH"
    socat -,raw,echo=0,icanon=0,isig=0,icrnl=0,escape=0x0f unix-connect:$1
  '';
in runCommand "vm" {} ''
  mkdir -p $out/bin
  cd  $out/bin
  ln -s ${connect} ./connect-vm
  ln -s ${run-liminix-vm} ./run-liminix-vm
''
