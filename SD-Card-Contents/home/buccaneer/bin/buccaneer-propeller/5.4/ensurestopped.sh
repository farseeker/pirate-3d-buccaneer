#! /bin/sh
VERSION=5.4
PIDS=`ps auxwww | grep propeller | grep -v "grep" | awk '{print $2}'`
if [ -z "$PIDS" ]; then
        echo "No instance of propeller " $VERSION " running." 1>&2
else
        for PID in $PIDS; do
                (while [ -r /tmp/propeller_busy ] ; do sleep 10 ; done ; kill -9 $PID) &           
        done
        echo "Killed one instance of running propeller " $VERSION
fi
exit 0
