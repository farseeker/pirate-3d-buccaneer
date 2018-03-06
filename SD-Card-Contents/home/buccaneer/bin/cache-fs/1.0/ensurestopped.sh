#! /bin/sh
VERSION=1.0
PIDS=`ps auxwww | grep cache-file-system/$VERSION/pirate_cache | grep -v "grep" | awk '{print $2}'`
if [ -z "$PIDS" ]; then
	echo "No instance of cache file system (pirate_cache)" $VERSION "running." 1>&2
else
	for PID in $PIDS; do
		kill -9 $PID
  	done
	echo "Killed one instance of running cache-file-system (pirate_cache)" $VERSION 
fi
exit 0
