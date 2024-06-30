{
  s6-linux-init,
  execline,
  writeScript,
  stdenvNoCC,
  lib,
  s6-rc,
}:
let
  hpr = name: arg: writeScript name ''
    #!${execline}/bin/execlineb -S0
    ${s6-linux-init}/bin/s6-linux-init-hpr ${arg} \$@
  '';
  init = writeScript "init" ''
    #!${execline}/bin/execlineb -S0
    ${s6-linux-init}/bin/s6-linux-init -c /etc/s6-linux-init/current -m 0022 -p ${lib.makeBinPath [execline s6-linux-init s6-rc]}:/usr/bin:/bin -d /dev -- "\$@"
  '';
in stdenvNoCC.mkDerivation {
  name = "s6-init-bin";
  phases = ["installPhase"];
  installPhase = ''
    bin=$out/bin
    mkdir -p $bin
    cd $bin
    ln -s ${s6-linux-init}/bin/s6-linux-init-shutdown shutdown
    ln -s ${s6-linux-init}/bin/s6-linux-init-telinit telinit
    ln -s ${hpr "reboot" "-r"} reboot
    ln -s ${hpr "poweroff" "-p"} poweroff
    ln -s ${hpr "halt" "-h"} halt
    ln -s ${init} init
  '';
}
