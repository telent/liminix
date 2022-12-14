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
test -n "$run" && (echo -e "$run" > $out/${name}/run)
test -n "${notificationFd}" && (echo ${notificationFd} > $out/${name}/notification-fd)
test -n "$up" && (echo -e "$up" > $out/${name}/up)
test -n "$down" && (echo -e "$down" > $out/${name}/down)
( cd $out && ln -s /run/service-state/${name} ./.outputs )
for i in $out/${name}/{down,up,run} ; do test -f $i && chmod +x $i; done
true
# (echo  $out/${name} && cd $out/${name} && find . -ls)
