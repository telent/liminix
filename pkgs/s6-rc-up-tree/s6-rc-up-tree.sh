service=$1

blocks=""
for controlled in $(cd /run/services/controlled/ && echo *); do
    down=$(s6-rc -b -un0 change $controlled)
    echo $controlled
    if test -n "$down"; then
	blocks="$blocks $controlled "
    fi
done

for s in $(s6-rc-db -d all-dependencies $service); do
    start=$s
    for dep in $(s6-rc-db all-dependencies $s); do
	case "$blocks" in
	    "* $dep *")
		echo "not starting $s, blocked by $dep"
		start=""
		;;
	    *)
		;;
	esac
    done
    if test -n "$start" ; then
	echo "starting $s because $service"
	s6-rc -b -u change $s
    fi
done
