#!/bin/bash

export HOME
case "$1" in
    start)
	PIDS1=`ps auxwww | grep 'dhcpcd eth0' | grep -v "grep" | awk '{print $2}'`

	#echo $PIDS1
	#echo $PIDS2

	if [ -z "$PIDS1" ]; then
		dhcpcd eth0
	else
		echo "Ethernet already running"
	fi

    ;;
    stop)

    ;;
    *)
        echo 'Usage: "Path to initEthernet" {start|stop}'
        exit 1
    ;;
esac
exit 0

