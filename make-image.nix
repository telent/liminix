pkgs: config:
let
  inherit (pkgs)
    callPackage
    closureInfo
    lib
    runCommand
    s6-rc
    stdenv
    stdenvNoCC
    writeScript
    writeText;

  # we need to generate s6 db,  by generating closure of all
  # config.services and calling s6-rc-compile on them
  allServices = closureInfo {
    rootPaths = builtins.attrValues config.services;
  };
  s6db = stdenvNoCC.mkDerivation  {
    name = "s6-rc-db";
    nativeBuildInputs = [pkgs.buildPackages.s6-rc];
    builder = writeText "find-s6-services" ''
    source $stdenv/setup
    mkdir -p $out
    srcs=""
    shopt -s nullglob
    for i in $(cat  ${allServices}/store-paths ); do
      if test -d $i; then
        for j in $i/* ; do
          if test -f $j/type ; then
            srcs="$srcs $i"
          fi
        done
      fi
    done
    echo s6-rc-compile $out/compiled $srcs
    s6-rc-compile $out/compiled $srcs
    '';
  };
  s6-pseudofiles = pkgs.s6-init-files;
  profile  = writeScript ".profile" ''
    PATH=${lib.makeBinPath (with pkgs; [busybox execline s6-linux-init s6-rc])}
    export PATH
  '';
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
     /bin/init s 0755 0 0 /etc/s6-linux-init/current/bin/init
     /bin/sh s 0755 0 0 ${pkgs.pkgsStatic.busybox}/bin/sh
     /bin/busybox s 0755 0 0 ${pkgs.busybox}/bin/busybox
     /etc/s6-rc d 0755 0 0
     /etc/s6-rc/compiled s 0755 0 0 ${s6db}/compiled
     /etc/passwd f 0644 0 0 echo  "root::0:0:root:/:/bin/sh"
     /.profile s 0644 0 0 ${profile}
  '';
  storefs = callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    storeContents = [ pseudofiles pkgs.strace s6-pseudofiles pkgs.pkgsStatic.busybox s6db pkgs.s6-linux-init ] ++ config.packages ;
    # comp =  "xz -Xdict-size 100%"
  };
in runCommand "frob-squashfs" {
    nativeBuildInputs = with pkgs.buildPackages; [ squashfsTools qprint ];
  } ''
    cp ${storefs} ./store.img
    chmod +w store.img
    mksquashfs - store.img -no-recovery -quiet -no-progress  -root-becomes store -p "/ d 0755 0 0"
    mksquashfs - store.img -no-recovery -quiet -no-progress  -root-becomes nix  -pf ${pseudofiles} -pf ${s6-pseudofiles}
    cp store.img $out
  ''
