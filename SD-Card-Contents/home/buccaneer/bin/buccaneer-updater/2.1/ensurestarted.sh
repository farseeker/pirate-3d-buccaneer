#! /bin/sh
VERSION=2.1
ID_FILE="/tmp/buccaneer.id"
PIDS=`ps auxwww | grep updater.jar | grep -v "grep" | awk '{print $2}'`
if [ -z "$PIDS" ]; then

	exec<$ID_FILE	
 	  while read line
 	    do
    	      id="$( cut -d ' ' -f 1 <<< "$line" )"; 
		if [ "$id" = "id" ]; then
                        pid="$( cut -d ' ' -f 2 <<< "$line" )";
                fi

  	    done
	echo "No instance of Buccaneer-Updater " $VERSION "running." 1>&2
	echo "Starting Buccaneer-Updater "
	java -jar /home/buccaneer/bin/buccaneer-updater/current/updater.jar $pid &
else
	echo "Already running one instance Buccaneer-Updater " $VERSION 
fi
exit 0
