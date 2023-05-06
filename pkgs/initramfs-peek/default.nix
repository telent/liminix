{
  busybox
, pkgsBuildBuild
, runCommand
, cpio
, writeReferencesToFile
, writeScript
} :
let
  inherit (pkgsBuildBuild) gen_init_cpio;
  script =  writeScript "init" ''
    #!/bin/sh
    exec >/dev/console
    echo Running in initramfs
    PATH=${busybox}/bin:$PATH
    export PATH
    mount -t proc none /proc
    mount -t sysfs none /sys
    ${busybox}/bin/sh
  '';
  refs = writeReferencesToFile busybox;
in runCommand "initramfs.cpio" { } ''
  cat << SPECIALS | ${gen_init_cpio}/bin/gen_init_cpio /dev/stdin > out
  dir /proc 0755 0 0
  dir /sys 0755 0 0
  dir /dev 0755 0 0
  nod /dev/console 0600 0 0 c 5 1
  nod /dev/mtdblock0 0600 0 0 b 31 0
  dir /nix 0755 0 0
  dir /nix/store 0755 0 0
  dir /bin 0755 0 0
  file /bin/sh  ${busybox}/bin/sh 0755 0 0
  file /init ${script} 0755 0 0
  SPECIALS
  find $(cat ${refs}) | ${pkgsBuildBuild.cpio}/bin/cpio -H newc -o -A -v -O out
  cp out $out
''
