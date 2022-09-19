source $stdenv/setup
mkdir -p $out/${name}
echo $type > $out/${name}/type
mkdir -p $out/${name}/dependencies.d
echo $buildInputs > $out/buildInputs
test -n "$dependencies" && for d in "$dependencies"; do
    touch $out/${name}/dependencies.d/$d
done
test -n "$contents" && for d in "$contents"; do
    mkdir -p $out/${name}/contents.d
    touch $out/${name}/contents.d/$d
done
test -n "$run" && (echo "$run" > $out/${name}/run)
test -n "$up" && (echo "$up" > $out/${name}/up)
test -n "$down" && (echo "$down" > $out/${name}/down)
(echo  $out/${name} && cd $out/${name} && find . -ls)
