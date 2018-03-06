#! /bin/bash

export HOME
case "$1" in
    start)
    	PIDS=`ps auxwww | grep hostapd | grep -v "grep" | awk '{print $2}'`

    	if [ -z "$PIDS" ]; then
    		echo "Turning On Wifi as Access Point"
    		#Initial wifi interface configuration
    		ifconfig wifi0 up 10.0.0.1 netmask 255.255.255.0
    		sleep 2

    		###########Start dnsmasq, modify if required##########
    		if [ -z "$(ps -e | grep dnsmasq)" ]
    		then
    		  dnsmasq
    		fi
    		###########
    		#start hostapd
    		hostapd -B -P /var/run/hostapd.pid /etc/hostapd/hostapd.conf 1> /dev/null

    	else
    		echo "Wifi already running in Access Point"
    	fi

    ;;
    stop)
		PIDS=`ps auxwww | grep hostapd | grep -v "grep" | awk '{print $2}'`

    	if [ "$PIDS" ]; then
    		echo "Turning Off Wifi as Access Point"
    		[ -f /var/run/hostapd.pid ] && kill `cat /var/run/hostapd.pid` &> /dev/null
    		killall dnsmasq

    		for PID in $PIDS; do
    			sudo kill -9 $PID
    		done
    	else
    		echo "Wifi not running in Access Point"
    	fi
    ;;
    *)
		echo 'Usage: "Path to initAP" {start|stop}'
		exit 1
    ;;
esac
exit 0

