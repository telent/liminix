{
  liminix,
  lib,
  targets ? [ ],
  kernel ? null,
  runCommand,
  pkgsBuildBuild,
  dependencies ? [ ],
}:
let
  inherit (liminix.services) oneshot;
  inherit (lib) concatStringsSep;
  loader =
    runCommand "modules"
      {
        nativeBuildInputs = with pkgsBuildBuild; [
          kmod
          cpio
          gawk
        ];
      }
      ''
        kernel=${kernel.modulesupport}

        mkdir -p lib/modules/0.0
        (cd $kernel && find . -name \*.ko | cpio --verbose --make-directories -p $NIX_BUILD_TOP/lib/modules/0.0)
        cp $kernel/modules.* lib/modules/0.0
        depmod -b . 0.0

        (for i in ${lib.concatStringsSep " " targets}; do
          modprobe -S 0.0 -d  $NIX_BUILD_TOP --show-depends $i | sed "s,^insmod $NIX_BUILD_TOP/lib/modules/0.0/,,g"
        done) | awk '!a[$0]++' > load-order

        mkdir $out
        for i in $(cat load-order); do
          install -v $NIX_BUILD_TOP/lib/modules/0.0/$i -D $out/$i
        done
        echo "O=$out" > $out/load.sh
        sed "s,^,insmod \$O/,g" < load-order >> $out/load.sh
        echo "O=$out" > $out/unload.sh
        tac load-order | sed "s,^,rmmod \$O/,g" > $out/unload.sh
      '';
in
oneshot {
  name = "kmodloader-" + (concatStringsSep "-" targets);
  up = "sh ${loader}/load.sh";
  down = "sh ${loader}/unload.sh";
  inherit dependencies;
}
