{writeText}:
writeText "service-fns.sh" ''
  output() { cat $1/.outputs/$2; }
  output_path() { echo $(realpath $1/.outputs)/$2; }
  mkoutputs() {
    d=/run/service-state/$1
    mkdir -m 2751 -p $d && chown root:system $d
    echo $d
  }
  in_outputs() {
    cd `mkoutputs $1` && umask 0027
  }
''
