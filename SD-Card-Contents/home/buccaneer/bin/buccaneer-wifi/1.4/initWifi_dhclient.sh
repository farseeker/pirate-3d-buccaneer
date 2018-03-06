#!/bin/bash

export HOME
case "$1" in
    start)
	PIDS1=`ps auxwww | grep wpa_supplicant | grep -v "grep" | awk '{print $2}'`
	PIDS2=`ps auxwww | grep 'dhclient -1 wlan1' | grep -v "grep" | awk '{print $2}'`

	#echo $PIDS1
	#echo $PIDS2

	if [ -z "$PIDS1" ]; then
		if [ -z "$PIDS2" ]; then
        		echo "Turning On wifi to connect to internet"
			ip link set dev wlan1 up
        		wpa_supplicant -B -i wlan1 -c /etc/wpa_supplicant/wpa_supplicant.conf
        		if dhclient -1 wlan1
			then
				echo "Connected to Wifi"
			else
				echo "Not Connected"
			fi

		else
			for PID2 in $PIDS2; do
				sudo kill -9 $PID2
			done

			echo "Turning On wifi to connect to internet"
			ip link set dev wlan1 up
                        wpa_supplicant -B -i wlan1 -c /etc/wpa_supplicant/wpa_supplicant.conf

                        if dhclient -1 wlan1
			then
                                echo "Connected to Wifi"
                        else
                                echo "Not Connected"
                        fi

		fi

	elif [ "$PIDS1" ]; then
		if [ -z "$PIDS2" ]; then
			for PID1 in $PIDS1; do
				sudo kill -9 $PID1
			done

                        echo "Turning On wifi to connect to internet"
			ip link set dev wlan1 up
                        wpa_supplicant -B -i wlan1 -c /etc/wpa_supplicant/wpa_supplicant.conf

                        if dhclient -1 wlan1
			then
                                echo "Connected to Wifi"
                        else
                                echo "Not Connected"
                        fi

		else
			echo "Wifi already running"
		fi

#	else
#		echo "Wifi already running"
	fi

    ;;
    stop)
	PIDS1=`ps auxwww | grep wpa_supplicant | grep -v "grep" | awk '{print $2}'`
        PIDS2=`ps auxwww | grep "dhclient -1 wlan1" | grep -v "grep" | awk '{print $2}'`

	#echo $PIDS1
	#echo $PIDS2

        if [ "$PIDS1" ]; then
		if [ "$PIDS2" ]; then
	        	echo "Turning Off wifi to disconnect to internet"
        		#LCD_PID=`ps auxwww | grep wpa_supplicant | grep -v "grep" | awk '{print $2}'`
        		#kill $LCD_PID

        		#LCD_PID=`ps auxwww | grep 'dhclient -1 wlan1' | grep -v "grep" | awk '{print $2}'`
        		#kill $LCD_PID

			for PID1 in $PIDS1; do
				sudo kill -9 $PID1
			done

			for PID2 in $PIDS2; do
				sudo kill -9 $PID2
			done

			#[ -f /var/run/dhclient.pid ] && kill `cat /var/run/dhclient.pid` &> /dev/null
			ip link set dev wlan1 down
		else
			echo "Turning Off wifi to disconnect to internet"
			for PID1 in $PIDS1; do
				sudo kill -9 $PID1
			done
			#[ -f /var/run/dhclient.pid ] && kill `cat /var/run/dhclient.pid` &> /dev/null
			ip link set dev wlan1 down
		fi

	elif [ -z "$PIDS1" ]; then
		if [ "$PIDS2" ]; then
			echo "Turning off wifi to disconnect to internet"
			for PID2 in $PIDS2; do
				sudo kill -9 $PID2
			done
		 #[ -f /var/run/dhclient.pid ] && kill `cat /var/run/dhclient.pid` &> /dev/null
		 ip link set dev wlan1 down
		else
			echo "Wifi not running"
		fi
	else
		echo "Wifi not running"
	fi
    ;;
    *)
        echo 'Usage: "Path to initWifi" {start|stop}'
        exit 1
    ;;
esac
exit 0

