#!/bin/bash

clientChannel=$(iwlist wifi1 channel | grep -oiE "Current.*Channel.*[0-9]+" | grep -oiE "Channel.*[0-9]+" | grep -oE "[0-9]+" | head -1)
APChannel=$(cat /etc/hostapd/hostapd.conf | grep -i channel | tr -cd '0-9' | head -1)

if [ ! -z "$clientChannel" -a ! -z "$APChannel" ]; then
	if [ $(($(($clientChannel-$APChannel)) * $(($clientChannel-$APChannel)))) -lt 25 ]; then
		echo "Client & AP Channels are overlapped..." 
		echo "Client Channel : $clientChannel"
		echo "AP Channel : $APChannel"
		APChannel=$(($(($clientChannel + 5)) % 11 + 1))
		sed -i "s/^channel=.*$/channel=$APChannel/" /etc/hostapd/hostapd.conf
		sync
		echo "AP Channel is changed to : $APChannel"
		bash /home/buccaneer/bin/buccaneer-wifi/current/initAP.sh stop
		bash /home/buccaneer/bin/buccaneer-wifi/current/initAP.sh start
	fi
fi



