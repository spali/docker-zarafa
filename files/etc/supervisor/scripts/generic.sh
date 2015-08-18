#!/bin/bash
thisPID=$$
startCommand=${1}
stopCommand=${2}
startDelay=${3}

function stopService {
	# stop service
	eval ${stopCommand}
	# be sure to kill the sleep and other child process
	pkill -P ${thisPID}
	exit 0
}

# stop service when exiting
trap stopService EXIT

# delay if defined
if [ -n "${startDelay}" ]; then
	sleep ${startDelay}
fi

# start service
eval ${startCommand}

# avoid exiting if service forks and master exits
sleep infinity  

