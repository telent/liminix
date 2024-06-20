{writeText}:
writeText "service-fns.sh" ''
  output() { cat $1/.outputs/$2; }
  output_word() {
    set -f
    local i=1
    for var in $(cat $1/.outputs/$2); do
      if test "$i" == "$3" ; then
        echo $var
      fi
      i=$(expr $i + 1)
    done
    set +f
  }

  output_path() { echo $(realpath $1/.outputs)/$2; }
  SERVICE_OUTPUTS=/run/services/outputs
  SERVICE_STATE=/run/services/state
  mkoutputs() {
    d=$SERVICE_OUTPUTS/$1
    mkdir -m 2751 -p $d && chown root:system $d
    echo $d
  }
  mkstate() {
    d=$SERVICE_STATE/$1
    mkdir -m 2751 -p $d && chown root:system $d
    echo $d
  }
  in_outputs() {
    cd `mkoutputs $1` && umask 0027
  }
''
