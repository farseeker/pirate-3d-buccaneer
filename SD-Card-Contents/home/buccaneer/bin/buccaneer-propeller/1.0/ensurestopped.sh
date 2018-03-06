#! /bin/sh
VERSION=1.0
PIDS=`ps auxwww | grep propeller | grep -v "grep" | awk '{print $2}'`
if [ -z "$PIDS" ]; then
	echo "No instance of propeller " $VERSION " running." 1>&2
else
	for PID in $PIDS; do
		kill -9 $PID
  	done
	echo "Killed one instance of running propeller " $VERSION 
fi
exit 0
