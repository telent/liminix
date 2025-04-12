source $stdenv/setup
mkdir -p $out/${name}

writepath(){
    mkdir -p $(dirname $1)
    if test -n "$2" ; then ( echo $2 > $1 ) ;fi
}
if test -n "$propertiesText"; then
    mkdir $out/.properties
    ( cd $out/.properties; eval "$propertiesText" )
fi

echo $serviceType > $out/${name}/type
mkdir -p $out/${name}/dependencies.d
echo $buildInputs > $out/buildInputs
test -n "$dependencies" && for path in $dependencies; do
    d=$(dirname $(cd ${path} && ls -d */type))
    touch $out/${name}/dependencies.d/$d
done
test -n "$contents" && for path in $contents; do
    d=$(dirname $(cd ${path} && ls -d */type))
    mkdir -p $out/${name}/contents.d
    touch $out/${name}/contents.d/$d
done

if test -n "$controller" ; then
    d=$(dirname $(cd ${controller} && ls -d */type))
    echo "$d)" > $out/${name}/controller
    #       ^ why is there a closing paren here?
    touch $out/${name}/dependencies.d/controlled
fi

for i in timeout-up timeout-down run notification-fd up down finish consumer-for producer-for pipeline-name restart-on-upgrade; do
    test -n "$(printenv $i)" && (echo "$(printenv $i)" > $out/${name}/$i)
done

( cd $out && ln -s /run/services/outputs/${name} ./.outputs )
for i in $out/${name}/{down,up,run} ; do test -f $i && chmod +x $i; done
true
