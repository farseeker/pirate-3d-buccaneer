#!/bin/bash
varLog="/var/log/staticWifiNames.log"
tmpLock="/tmp/staticWifiNames.lock"
stateFile="/tmp/wifiState.id"

date > $varLog

#Check if SSID is correct, otherwise write the correct SSID before proceeding
while [ -z /tmp/buccaneer.id ]; do
	sleep 0.1
	echo "Waiting for /tmp/buccaneer.id" >> $varLog
done

ssid=`cat /tmp/buccaneer.id | grep prettyId | awk '{print $2}'`
wifiPasswd=`cat /tmp/buccaneer.id | grep wifiPassword | awk '{print $2}'`
ssidHostapd=`cat /etc/hostapd/hostapd.conf | grep -oE "Buccaneer-[0-9a-zA-Z]+"`

if [ "$ssid" != "$ssidHostapd" ]; then
	echo "SSIDs are not matching, Writing correct SSID in hostapd.conf" >> $varLog
	sed -i "s/^ssid=.*$/ssid=$ssid/" /etc/hostapd/hostapd.conf
	sed -i "s/^wpa_passphrase=.*$/wpa_passphrase=$wifiPasswd/" /etc/hostapd/hostapd.conf
	sync
else
	echo "SSIDs are matched" >> $varLog
fi

dongleId5GHz="ID 7392:a81"
dongleId2GHz="ID 7392:7811"

dongle5GHzPresent=0
dongle2GHzPresent=0
usb2GHz=0
usb5GHz=0
usb2GHz1=0
usb2GHz2=0
usb5GHz1=0
usb5GHz2=0
stateNow=0

dongle5GHzPresent=$(lsusb | grep -oE "$dongleId5GHz" | wc -l)
dongle2GHzPresent=$(lsusb | grep -oE "$dongleId2GHz" | wc -l)
echo "dongle5GHzPresent=$dongle5GHzPresent" >> $varLog
echo "dongle2GHzPresent=$dongle2GHzPresent" >> $varLog

#States
#0 : No state file available
#1 : 1 2GHz
#2 : 2 2GHz
#3 : 1 5GHz
#4 : 2 5GHz
#5 : 1 2GHz,1 5GHz
#6 : No Dongles

if [ -f $stateFile ];then
	statePrev=$(cat $stateFile)
else
	statePrev=0
fi
echo "statePrev=$statePrev" >> $varLog

if [ $dongle2GHzPresent -eq 0 ] && [ $dongle5GHzPresent -eq 0 ]; then
	echo "No dongles detected" >> $varLog
	stateNow=6
	echo "stateNow=$stateNow" >> $varLog
	echo $stateNow >  $stateFile
	rm /tmp/macAddr2GHz1 /tmp/macAddr2GHz2 /tmp/macAddr5GHz /tmp/macAddr2GHz /tmp/macAddr5GHz1
elif [ $dongle2GHzPresent -eq 1 ] && [ $dongle5GHzPresent -eq 0 ]; then
	echo "Only one 2.4GHz dongle detected" >> $varLog
	stateNow=1
	echo "stateNow=$stateNow" >> $varLog
	echo $stateNow >  $stateFile
	usb2GHz=$(grep -rHsiE "PRODUCT=.*7811" /sys/devices/platform | grep -oE "usb[0-9]+" | uniq)
	echo "usb2GHz:$usb2GHz" >> $varLog
	usb2GHzInterface=$(ls /sys/class/net/ -l | grep "$usb2GHz" | grep -oE "[a-z0-9A-Z]+[ ][-][>]" | grep -oE "[a-zA-Z0-9]+")
	echo "usb2GHzInterface:$usb2GHzInterface" >> $varLog
	macAddr2GHz=$(cat /sys/class/net/$usb2GHzInterface/address)
	echo "macAddr2GHz:$macAddr2GHz" >> $varLog
	if [ $statePrev -eq 5 -a -f /tmp/macAddr2GHz ];then
		#Existing AP
		macAP=$(cat /tmp/macAddr2GHz)
		echo "macAP:$macAP" >> $varLog
		usb2GHz=0
		usb2GHzInterface=0
		macAddr2GHz=0
		echo "No change in AP; Exiting..." >> $varLog
		echo "$macAP" > /tmp/macAddr2GHz
	elif [ $statePrev -eq 2 -a -f /tmp/macAddr2GHz1 ];then
		#If AP not removed, Existing AP
		macAP=$(cat /tmp/macAddr2GHz1)
		echo "macAP:$macAP" >> $varLog
		if [ "$macAP" == "$macAddr2GHz" ];then
			usb2GHz=0
			usb2GHzInterface=0
			macAddr2GHz=0
			echo "No change in AP; Exiting..." >> $varLog
			echo "$macAP" > /tmp/macAddr2GHz
		fi
	fi
	rm /tmp/macAddr2GHz1 /tmp/macAddr2GHz2 /tmp/macAddr5GHz /tmp/macAddr5GHz1 
elif [ $dongle2GHzPresent -eq 0 ] && [ $dongle5GHzPresent -eq 1 ]; then
	echo "Only one 5GHz dongle detected. Cannot create AP." >> $varLog
	stateNow=3
	echo "stateNow=$stateNow" >> $varLog
	echo $stateNow >  $stateFile
	usb5GHz=$(grep -rHsiE "PRODUCT=.*a81" /sys/devices/platform | grep -oE "usb[0-9]+" | uniq)
	echo "usb5GHz:$usb5GHz" >> $varLog
	usb5GHzInterface=$(ls /sys/class/net/ -l | grep "$usb5GHz" | grep -oE "[a-z0-9A-Z]+[ ][-][>]" | grep -oE "[a-zA-Z0-9]+")
	echo "usb5GHzInterface:$usb5GHzInterface" >> $varLog
	macAddr5GHz=$(cat /sys/class/net/$usb5GHzInterface/address)
	echo "macAddr5GHz:$macAddr5GHz" >> $varLog
	if [ $statePrev -eq 5 -a -f /tmp/macAddr5GHz ];then
		#Existing Client
		macAP=$(cat /tmp/macAddr5GHz)
		echo "macAP:$macAP" >> $varLog
		usb5GHz=0
		usb5GHzInterface=0
		macAddr5GHz=0
		echo "No change in Client; Exiting..." >> $varLog
		echo "$macAP" > /tmp/macAddr5GHz
	elif [ $statePrev -eq 4 -a -f /tmp/macAddr5GHz1 ];then
		#If Client not removed, Existing Client
		macAP=$(cat /tmp/macAddr5GHz1)
		echo "macAP:$macAP" >> $varLog
		if [ "$macAP" == "$macAddr5GHz" ];then
			usb5GHz=0
			usb5GHzInterface=0
			macAddr5GHz=0
			echo "No change in Client; Exiting..." >> $varLog
			echo "$macAP" > /tmp/macAddr5GHz
		fi
	fi
	rm /tmp/macAddr2GHz1 /tmp/macAddr2GHz2 /tmp/macAddr2GHz /tmp/macAddr5GHz1

elif [ $dongle2GHzPresent -eq 1 ] && [ $dongle5GHzPresent -eq 1 ]; then
	echo "One 2.4GHz & One 5GHz dongle detected" >> $varLog
	stateNow=5
	echo "stateNow=$stateNow" >> $varLog
	echo $stateNow >  $stateFile
	usb2GHz=$(grep -rHsiE "PRODUCT=.*7811" /sys/devices/platform | grep -oE "usb[0-9]+" | uniq)
	usb5GHz=$(grep -rHsiE "PRODUCT=.*a81" /sys/devices/platform | grep -oE "usb[0-9]+" | uniq)
	usb2GHzInterface=$(ls /sys/class/net/ -l | grep "$usb2GHz" | grep -oE "[a-z0-9A-Z]+[ ][-][>]" | grep -oE "[a-zA-Z0-9]+")
	usb5GHzInterface=$(ls /sys/class/net/ -l | grep "$usb5GHz" | grep -oE "[a-z0-9A-Z]+[ ][-][>]" | grep -oE "[a-zA-Z0-9]+")
	macAddr2GHz=$(cat /sys/class/net/$usb2GHzInterface/address)
	macAddr5GHz=$(cat /sys/class/net/$usb5GHzInterface/address)
	echo "usb2GHz:$usb2GHz  usb5GHz:$usb5GHz" >> $varLog
	echo "usb2GHzInterface:$usb2GHzInterface  usb5GHzInterface:$usb5GHzInterface" >> $varLog
	echo "macAddr2GHz:$macAddr2GHz  macAddr5GHz:$macAddr5GHz" >> $varLog
	if [ $statePrev -eq 1 -a -f /tmp/macAddr2GHz ];then
		#Existing AP
		#New Client
		macAP=$(cat /tmp/macAddr2GHz)
		echo "macAP:$macAP" >> $varLog	
		usb2GHz=0
		usb2GHzInterface=0
		macAddr2GHz=0
		echo "No change in AP; Client is being re-initialized" >> $varLog
		echo "$macAP" > /tmp/macAddr2GHz
	elif [ $statePrev -eq 3 -a -f /tmp/macAddr5GHz ];then
		#Existing Client
		#New AP
		macAP=$(cat /tmp/macAddr5GHz)
		echo "macAP:$macAP" >> $varLog
		usb5GHz=0
		usb5GHzInterface=0
		macAddr5GHz=0
		echo "No change in Client; AP is being re-initialized" >> $varLog
		echo "$macAP" > /tmp/macAddr5GHz
	fi
	rm /tmp/macAddr2GHz1 /tmp/macAddr2GHz2 /tmp/macAddr5GHz1

elif [ $dongle2GHzPresent -eq 2 ] && [ $dongle5GHzPresent -eq 0 ]; then
	echo "Both the dongles are 2.4GHz" >> $varLog
	stateNow=2
	echo "stateNow=$stateNow" >> $varLog
	echo $stateNow >  $stateFile
	usb2GHz1=$(grep -rHsiE "PRODUCT=.*7811" /sys/devices/platform | grep -oE "usb[0-9]+" | uniq | head -1)
	usb2GHz2=$(grep -rHsiE "PRODUCT=.*7811" /sys/devices/platform | grep -oE "usb[0-9]+" | uniq | tail -1)
	usb2GHz1Interface=$(ls /sys/class/net/ -l | grep "$usb2GHz1" | grep -oE "[a-z0-9A-Z]+[ ][-][>]" | grep -oE "[a-zA-Z0-9]+")
	usb2GHz2Interface=$(ls /sys/class/net/ -l | grep "$usb2GHz2" | grep -oE "[a-z0-9A-Z]+[ ][-][>]" | grep -oE "[a-zA-Z0-9]+")
	macAddr2GHz1=$(cat /sys/class/net/$usb2GHz1Interface/address)
	macAddr2GHz2=$(cat /sys/class/net/$usb2GHz2Interface/address)
	echo "usb2GHz1:$usb2GHz1  usb2GHz2:$usb2GHz2" >> $varLog
	echo "usb2GHz1Interface:$usb2GHz1Interface  usb2GHz2Interface:$usb2GHz2Interface" >> $varLog
	echo "macAddr2GHz1:$macAddr2GHz1  macAddr2GHz2:$macAddr2GHz2" >> $varLog
	if [ $statePrev -eq 1 -a -f /tmp/macAddr2GHz ];then
		#Existing AP
		#New Client
		macAP=$(cat /tmp/macAddr2GHz)
		echo "macAP:$macAP" >> $varLog
		if [ "$macAP" == "$macAddr2GHz2" ];then 
			usb2GHz2=$usb2GHz1
			usb2GHz2Interface=$usb2GHz1Interface
			macAddr2GHz2=$macAddr2GHz1
		fi
		usb2GHz1=0
		usb2GHz1Interface=0
		macAddr2GHz1=0
		echo "No change in AP; Client is being re-initialized" >> $varLog
		echo "$macAP" > /tmp/macAddr2GHz1
	fi 
	rm /tmp/macAddr2GHz /tmp/macAddr5GHz /tmp/macAddr5GHz1

elif [ $dongle2GHzPresent -eq 0 ] && [ $dongle5GHzPresent -eq 2 ]; then
	echo "Both the dongles are 5GHz. Cannot create AP." >> $varLog
	stateNow=4
	echo "stateNow=$stateNow" >> $varLog
	echo $stateNow >  $stateFile
	usb5GHz1=$(grep -rHsiE "PRODUCT=.*a81" /sys/devices/platform | grep -oE "usb[0-9]+" | uniq | head -1)
	usb5GHz2=$(grep -rHsiE "PRODUCT=.*a81" /sys/devices/platform | grep -oE "usb[0-9]+" | uniq | tail -1)
	usb5GHzInterface1=$(ls /sys/class/net/ -l | grep "$usb5GHz1" | grep -oE "[a-z0-9A-Z]+[ ][-][>]" | grep -oE "[a-zA-Z0-9]+")
	usb5GHzInterface2=$(ls /sys/class/net/ -l | grep "$usb5GHz2" | grep -oE "[a-z0-9A-Z]+[ ][-][>]" | grep -oE "[a-zA-Z0-9]+")
	macAddr5GHz1=$(cat /sys/class/net/$usb5GHzInterface1/address)
	macAddr5GHz2=$(cat /sys/class/net/$usb5GHzInterface2/address)
	echo "usb5GHz1:$usb5GHz1  usb5GHz2:$usb5GHz2" >> $varLog
	echo "usb5GHzInterface1:$usb5GHzInterface1  usb5GHzInterface2:$usb5GHzInterface2" >> $varLog
	echo "macAddr5GHz1:$macAddr5GHz1  macAddr5GHz2:$macAddr5GHz2" >> $varLog

	if [ $statePrev -eq 3 -a -f /tmp/macAddr5GHz ];then
		#Existing AP
		#No Client
		macAP=$(cat /tmp/macAddr5GHz)
		echo "macAP:$macAP" >> $varLog
		if [ "$macAP" == "$macAddr5GHz1" ] || [ "$macAP" == "$macAddr5GHz2" ];then
			usb5GHz1=0
			usb5GHz1Interface=0
			macAddr5GHz1=0
		fi
		echo "No change in AP; Client is being removed" >> $varLog
		echo "$macAP" > /tmp/macAddr5GHz1
	fi
	rm /tmp/macAddr2GHz /tmp/macAddr2GHz1 /tmp/macAddr2GHz2 /tmp/macAddr5GHz
fi

if [ "$usb2GHz" != "0" ]; then
	#Renaming 2.4GHz Interface to wifi0
	echo "Renaming 2.4GHz Interface to wifi0" >> $varLog
	ifconfig $usb2GHzInterface down
	ip link set $usb2GHzInterface name wifi0
	ifconfig wifi0 up
	echo "$macAddr2GHz" > /tmp/macAddr2GHz
	bash /home/buccaneer/bin/buccaneer-wifi/current/initAP.sh stop
	bash /home/buccaneer/bin/buccaneer-wifi/current/initAP.sh start
	echo "AP is re-initialized, because of dongle attach/detach" >> $varLog
fi

if [ "$usb2GHz1" != "0" ]; then
	#Renaming 1st 2.4GHz(incase of two 2.4GHz) Interface to wifi0
	echo "Renaming 1st 2.4GHz(incase of two 2.4GHz) Interface to wifi0" >> $varLog
	ifconfig $usb2GHz1Interface down
	ip link set $usb2GHz1Interface name wifi0
	ifconfig wifi0 up
	echo "$macAddr2GHz1" > /tmp/macAddr2GHz1
	bash /home/buccaneer/bin/buccaneer-wifi/current/initAP.sh stop
	bash /home/buccaneer/bin/buccaneer-wifi/current/initAP.sh start
	echo "AP is re-initialized, because of dongle attach/detach" >> $varLog
fi

if [ "$usb5GHz" != "0" ]; then
	#Renaming 5GHz Interface to wifi1
	echo "Renaming 5GHz Interface to wifi1" >> $varLog
	ifconfig $usb5GHzInterface down
	ip link set $usb5GHzInterface name wifi1
	ifconfig wifi1 up
	echo "$macAddr5GHz" > /tmp/macAddr5GHz 
	bash /home/buccaneer/bin/buccaneer-wifi/current/initWifi.sh stop
	bash /home/buccaneer/bin/buccaneer-wifi/current/initWifi.sh start
	echo "Client is re-initialized, because of dongle attach/detach" >> $varLog
fi

if [ "$usb2GHz2" != "0" ]; then
	#Renaming 2nd 2.4GHz(incase of two 2.4GHz) Interface to wifi1
	echo "Renaming 2nd 2.4GHz(incase of two 2.4GHz) Interface to wifi1" >> $varLog
	ifconfig $usb2GHz2Interface down
	ip link set $usb2GHz2Interface name wifi1
	ifconfig wifi1 up
	echo "$macAddr2GHz2" > /tmp/macAddr2GHz2
	bash /home/buccaneer/bin/buccaneer-wifi/current/initWifi.sh stop
	bash /home/buccaneer/bin/buccaneer-wifi/current/initWifi.sh start
	echo "Client is re-initialized, because of dongle attach/detach" >> $varLog
fi

if [ "$usb5GHz1" != "0" ]; then
	#Renaming 1st 5GHz(incase of two 5GHz) Interface to wifi1
	echo "Renaming 1st 5GHz(incase of two 5GHz) Interface to wifi1" >> $varLog
	ifconfig $usb5GHzInterface1 down
	ip link set $usb5GHzInterface1 name wifi1
	ifconfig wifi1 up
	echo "$macAddr5GHz1" > /tmp/macAddr5GHz1
	bash /home/buccaneer/bin/buccaneer-wifi/current/initWifi.sh stop
	bash /home/buccaneer/bin/buccaneer-wifi/current/initWifi.sh start
	echo "Client is re-initialized, because of dongle attach/detach" >> $varLog
fi

sync
