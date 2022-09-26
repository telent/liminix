{
  stdenv
, busybox
, buildPackages
, callPackage
, execline
, lib
, pseudofile
, runCommand
, s6-init-bin
, s6-init-files
, s6-linux-init
, s6-rc
, s6-rc-database
, stdenvNoCC
, writeScript
, writeText
} : config :
let
  pseudofiles = writeText "pseudofiles" ''
     / d 0755 0 0
     /bin d 0755 0 0
     /etc d 0755 0 0
     /run d 0755 0 0
     /dev d 0755 0 0
     /dev/null c 0666 root root 1 3
     /dev/zero c 0666 root root 1 5
     /dev/tty1 c 0777 root root 4 1
     /dev/tty2 c 0777 root root 4 2
     /dev/tty3 c 0777 root root 4 3
     /dev/tty4 c 0777 root root 4 4
     /dev/tty c 0777 root root 5 0
     /dev/console c 0600 root root 5 1
     /proc d 0555 root root
     /sys d 0555 root root
     /dev/pts d 0755 0 0
     /etc/init.d d 0755 0 0
     /bin/init s 0755 0 0 ${s6-init-bin}/bin/init
     /bin/sh s 0755 0 0 ${busybox}/bin/sh
     /bin/busybox s 0755 0 0 ${busybox}/bin/busybox
     /etc/passwd f 0644 0 0 echo  "root::0:0:root:/:/bin/sh"
  '';

  config-pseudofiles = pseudofile.write "config.etc"
    (config.environment.contents);

  storefs = callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    # add pseudofiles to store so that the packages they
    # depend on are also added
    storeContents = [
      pseudofiles
      s6-init-files
      config-pseudofiles
    ] ++ config.packages ;
  };
in runCommand "frob-squashfs" {
    nativeBuildInputs = with buildPackages; [ squashfsTools qprint ];
  } ''
    cp ${storefs} ./store.img
    chmod +w store.img
    mksquashfs - store.img -no-recovery -quiet -no-progress  -root-becomes store -p "/ d 0755 0 0"
    mksquashfs - store.img -no-recovery -quiet -no-progress  -root-becomes nix  -pf ${pseudofiles} -pf ${s6-init-files} -pf ${config-pseudofiles}
    cp store.img $out
  ''
