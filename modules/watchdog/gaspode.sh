#!/bin/sh
deadline=$(expr $(date +%s) + ${HEADSTART})
services=$@
echo started feeding the dog
exec 3> ${WATCHDOG-/dev/watchdog}

healthy(){
    test $(date +%s) -le $deadline && return 0

    for i in $services; do
	if test "$(s6-svstat -o up /run/service/$i)" != "true" ; then
	   echo "service $i is down"
	   return 1
	fi
    done
}

while healthy ;do
    sleep 10
    echo >&3
done
echo "stopped feeding the dog"
sleep 6000  # don't want s6-rc to restart
