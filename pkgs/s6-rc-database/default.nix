# generate s6-rc database,  by generating closure of all
# config.services and calling s6-rc-compile on them

{
  stdenvNoCC
, buildPackages
, closureInfo
, writeText
, services ? []
}:
let closure-info = closureInfo { rootPaths = services; };
in stdenvNoCC.mkDerivation  {
  name = "s6-rc-database";
  nativeBuildInputs = [buildPackages.s6-rc];
  builder = writeText "find-s6-services" ''
    source $stdenv/setup
    mkdir -p $out
    srcs=""
    shopt -s nullglob
    for i in $(cat  ${closure-info}/store-paths ); do
      if test -d $i; then
        for j in $i/* ; do
          if test -f $j/type ; then
            if test -e $j/restart-on-upgrade; then
              flag=force-restart
            else
              unset flag
            fi
            case $(cat $j/type) in
              longrun|oneshot)
                # s6-rc-update only wants atomics in its
                # restarts file
                echo $(basename $j) " " ''${flag-$i} >>  $out/hashes
                ;;
              *)
                ;;
            esac
            srcs="$srcs $i"
          fi
        done
      fi
    done
    s6-rc-compile $out/compiled $srcs
    s6-rc-db -c $out/compiled contents default
    mv $out/hashes $out/compiled
  '';
}
