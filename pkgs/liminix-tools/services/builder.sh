source $stdenv/setup
mkdir -p $out/${name}
echo $serviceType > $out/${name}/type
mkdir -p $out/${name}/dependencies.d
echo $buildInputs > $out/buildInputs
test -n "$dependencies" && for d in $dependencies; do
    touch $out/${name}/dependencies.d/$d
done
test -n "$contents" && for d in $contents; do
    mkdir -p $out/${name}/contents.d
    touch $out/${name}/contents.d/$d
done

for i in timeout-up timeout-down run notification-fd up down finish consumer-for producer-for pipeline-name restart-on-upgrade; do
    test -n "$(printenv $i)" && (echo "$(printenv $i)" > $out/${name}/$i)
done

( cd $out && ln -s /run/services/outputs/${name} ./.outputs )
for i in $out/${name}/{down,up,run} ; do test -f $i && chmod +x $i; done
true
