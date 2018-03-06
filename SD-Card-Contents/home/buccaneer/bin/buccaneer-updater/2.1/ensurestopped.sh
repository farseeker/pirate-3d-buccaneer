#! /bin/sh
VERSION=2.1
PIDS=`ps auxwww | grep updater.jar | grep -v "grep" | awk '{print $2}'`
if [ -z "$PIDS" ]; then
	echo "No instance of Buccaneer-Updater " $VERSION " running." 1>&2
else
	for PID in $PIDS; do
		kill -9 $PID
  	done
	echo "Killed one instance of running Buccaneer-Updater " $VERSION 
fi
exit 0
