#!/bin/bash

dongleId5GHz="ID 7392:a81"
dongleId2GHz="ID 7392:7811"

dongle5GHzPresent=0
dongle2GHzPresent=0

dongle5GHzPresent=$(lsusb | grep -oE "$dongleId5GHz" | wc -l)
dongle2GHzPresent=$(lsusb | grep -oE "$dongleId2GHz" | wc -l)

function message_turn_on_wifi()
{
	echo "TURNING ON WIFI"
}

function message_turn_off_wifi()
{
	echo "TURNING OFF WIFI"
}


function launchWpaSupplicant()
{
	if [ $dongle5GHzPresent -eq 0 -o "$dongle5GHzPresent" == "" ];then
		wpa_supplicant -B -Dwext -i wifi1 -c /etc/wpa_supplicant/wpa_supplicant.conf
		echo "2GHz"
	else
		wpa_supplicant -B -i wifi1 -c /etc/wpa_supplicant/wpa_supplicant.conf
		echo "5GHz"
	fi
	#echo "launchWpaSupplicant"
}

function launchDhcpcd()
{
	dhcpcd -d wifi1
	#echo "launchDhcpcd"
}

function startupInterface()
{
	ip link set dev wifi1 up
	#echo "startupInterface"
}

function shutdownInterface()
{
	ip link set dev wifi1 down
	#echo "shutdownInterface"
}

function flushOldIPAddr()
{
	ip addr flush dev wifi1
	#echo "flushOldIPAddr"
}

function getPIDWpaSupplicant()
{
	PID1=`ps auxwww | grep wpa_supplicant | grep -v "grep" | awk '{print $2}'`
	echo $PID1
}

function getPIDDhcpcd()
{
	PID2=`ps auxwww | grep dhcpcd | grep -v "grep" | awk '{print $2}'`
	echo $PID2
}

function initiateClient()
{
	startupInterface
	launchWpaSupplicant
	launchDhcpcd
	bash /home/buccaneer/bin/buccaneer-wifi/current/channelAllocation.sh
}

export HOME
case "$1" in
	start)
	PIDS1=$(getPIDWpaSupplicant)
		PIDS2=$(getPIDDhcpcd)
	#echo PIDS1:$PIDS1
	#echo PIDS2:$PIDS2

	if [ -z "$PIDS1" ]; then
		if [ -z "$PIDS2" ]; then
			message_turn_on_wifi
			initiateClient
		else
			for PID2 in $PIDS2; do sudo kill -9 $PID2; done
			while [ "$PIDS2" ]; do
				sleep 0.1
				echo "Killing dhcpcd..."
				PIDS2=$(getPIDDhcpcd)
			done
			message_turn_on_wifi
			initiateClient
		fi

	elif [ "$PIDS1" ]; then
		if [ -z "$PIDS2" ]; then
			for PID1 in $PIDS1; do sudo kill -9 $PID1; done
			while [ "$PIDS1" ]; do
				sleep 0.1
				echo "Killing wpa_supplicant..."
				PIDS1=$(getPIDWpaSupplicant)
			done
			message_turn_on_wifi
			initiateClient

		else
			echo "Wifi already running"
		fi
	fi

	;;
	stop)
	PIDS1=$(getPIDWpaSupplicant)
	PIDS2=$(getPIDDhcpcd)
	#echo PIDS1:$PIDS1
	#echo PIDS2:$PIDS2

	if [ "$PIDS1" ]; then
		if [ "$PIDS2" ]; then
			message_turn_off_wifi
			for PID1 in $PIDS1; do sudo kill -9 $PID1; done
			while [ "$PIDS1" ]; do
				sleep 0.1
				echo "Killing wpa_supplicant..."
				PIDS1=$(getPIDWpaSupplicant)
			done

			flushOldIPAddr
			for PID2 in $PIDS2; do sudo kill -9 $PID2; done
			while [ "$PIDS2" ]; do
				sleep 0.1
				echo "Killing dhcpcd..."
				PIDS2=$(getPIDDhcpcd)
			done
			#[ -f /var/run/dhcpcd-wifi1.pid ] && kill `cat /var/run/dhcpcd-wifi1.pid` &> /dev/null
			shutdownInterface
		else
			message_turn_off_wifi
			for PID1 in $PIDS1; do sudo kill -9 $PID1; done
			while [ "$PIDS1" ]; do
				sleep 0.1
				echo "Killing wpa_supplicant..."
				PIDS1=$(getPIDWpaSupplicant)
			done
			#[ -f /var/run/dhcpcd-wifi1.pid ] && kill `cat /var/run/dhcpcd-wifi1.pid` &> /dev/null
			shutdownInterface
		fi

	elif [ -z "$PIDS1" ]; then
		if [ "$PIDS2" ]; then
			message_turn_off_wifi
			flushOldIPAddr
			for PID2 in $PIDS2; do sudo kill -9 $PID2; done
			while [ "$PIDS2" ]; do
				sleep 0.1
				echo "Killing dhcpcd..."
				PIDS2=$(getPIDDhcpcd)
			done
			#[ -f /var/run/dhcpcd-wifi1.pid ] && kill `cat /var/run/dhcpcd-wifi1.pid` &> /dev/null
			shutdownInterface
		else
			echo "Wifi not running"
		fi
	fi
	;;
	*)
		echo 'Usage: "Path to initWifi" {start|stop}'
		exit 1
	;;
esac
exit 0

