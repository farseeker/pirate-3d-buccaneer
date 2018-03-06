#! /bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sh $DIR/initAP.sh stop
sh $DIR/initWifi.sh stop

exit 0

