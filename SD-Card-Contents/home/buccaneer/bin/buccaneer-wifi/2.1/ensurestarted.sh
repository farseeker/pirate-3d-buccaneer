#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PIDS=`ps auxwww | grep wifiConfig | grep -v "grep" | awk '{print $2}'`
KVER=`uname -r`

if [ ! -f "$DIR/configFiles.log" ]; then
	ssid=`cat /tmp/buccaneer.id | grep prettyId | awk '{print $2}'`
	wifiPasswd=`cat /tmp/buccaneer.id | grep wifiPassword | awk '{print $2}'`
	sed -i "s/^ssid=.*$/ssid=$ssid/" $DIR/configFiles/hostapd.conf
	sed -i "s/^wpa_passphrase=.*$/wpa_passphrase=$wifiPasswd/" $DIR/configFiles/hostapd.conf
	mkdir -p /etc/hostapd
	cp $DIR/configFiles/hostapd.conf /etc/hostapd/hostapd.conf
	cp $DIR/configFiles/dnsmasq.conf /etc/dnsmasq.conf
	cp $DIR/configFiles/dhcpcd.conf /etc/dhcpcd.conf

	mkdir -p /usr/lib/modules/$KVER/kernel/net/wireless
	cp $DIR/configFiles/8812au.ko /usr/lib/modules/$KVER/kernel/net/wireless/8812au.ko
	#To built the module dependencies and its path
	depmod
	#Load modules at run-time
	modprobe 8812au
	#Config to load 8812au.ko at bootup
	mkdir -p /etc/modules-load.d
	cp $DIR/configFiles/EW7811UTC.conf /etc/modules-load.d/EW7811UTC.conf

	#Config to detect dongle attach/detach
	chmod 755 $DIR/staticWifiNames.sh
	mkdir -p /etc/udev/rules.d
	cp $DIR/configFiles/wifiDongle-detect.rules /etc/udev/rules.d/wifiDongle-detect.rules
	udevadm control --reload

	sync

	bash $DIR/staticWifiNames.sh

	date > $DIR/configFiles.log
	echo "Old Config files are replaced" >> $DIR/configFiles.log
fi

if [ "$PIDS" ]; then
	echo "wifiConfig running. Bypassing start check."
	exit 0
fi

#Modify EW7811UN Dongle's parameters
#if [ ! -f /etc/modprobe.d/8192cu.conf ]; then
#		echo "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0 rtw_ips_mode=1" > /etc/modprobe.d/8192cu.conf
#fi
#check=$(cat /sys/module/8192cu/parameters/rtw_power_mgnt)
#if [ $check -ne 0 ]; then
#	echo 0 > /sys/module/8192cu/parameters/rtw_power_mgnt
#	echo 0 > /sys/module/8192cu/parameters/rtw_enusbss
#	echo 1 > /sys/module/8192cu/parameters/rtw_ips_mode
#fi

#Modify EW7811UTC Dongle's parameters
#if [ ! -f /etc/modprobe.d/8812au.conf ]; then
#	echo "options 8812au rtw_power_mgnt=0 rtw_enusbss=0 rtw_ips_mode=1" > /etc/modprobe.d/8812au.conf
#fi
#check=$(cat /sys/module/8812au/parameters/rtw_power_mgnt)
#if [ $check -ne 0 ]; then
#	echo 0 > /sys/module/8812au/parameters/rtw_power_mgnt
#	echo 0 > /sys/module/8812au/parameters/rtw_enusbss
#	echo 1 > /sys/module/8812au/parameters/rtw_ips_mode
#fi

if [ -f /tmp/staticWifiNames.lock ]; then # name according to bin/buccaneer-wifi/current/staticWifiNames.sh and /usr/bin/InitializePrinter
	rm /tmp/staticWifiNames.lock
	bash $DIR/wifiNames.sh
fi

#Restart Wifi, if the Router is restarted
isClientConnected=$(ifconfig wifi1 | grep -oE "[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}")
isClientHWDetected=$(ifconfig wifi1 | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
if [ "$isClientConnected" == "" ] && [ "$isClientHWDetected" != "" ];then
	bash $DIR/initWifi.sh stop
fi

bash $DIR/initAP.sh start
bash $DIR/initWifi.sh start

#To check and allocate the correct names for wifi dongles 2.4GHz & 5GHz
#bash $DIR/staticWifiNames.sh

exit 0

