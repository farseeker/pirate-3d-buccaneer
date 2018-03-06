#! /bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PIDS=`ps auxwww | grep wifiConfig | grep -v "grep" | awk '{print $2}'`

if [ "$PIDS" ]; then
	echo "wifiConfig running. Bypassing start check."
	exit 0
fi
	
sh $DIR/initAP.sh start
sh $DIR/initWifi.sh start

exit 0

