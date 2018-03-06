#! /bin/sh
PIDS=`ps auxwww | grep "propeller -k"  | grep -v "grep" | awk '{print $2}'`

if [ -z "$PIDS" ]; then

	ID_FILE="/tmp/buccaneer.id"
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	exec<$ID_FILE	
 	  while read line
 	    do
    	      id="$( cut -d ' ' -f 1 <<< "$line" )"; 
		if [ "$id" = "privKey" ]; then
	    		privKey="$( cut -d ' ' -f 2 <<< "$line" )";
		fi
                if [ "$id" = "id" ]; then
                        printerId="$( cut -d ' ' -f 2 <<< "$line" )";
                fi

  	    done

	echo "No instance of propeller running." 
	echo "Starting propeller"
	
	chmod -R 755 $DIR/propeller

	if [ -d /home/buccaneer/debug/log ] ; then

		logFileDate=$(date +%y-%m-%d_%T)
		$DIR/propeller -k $privKey > "/home/buccaneer/debug/log/propeller$logFileDate.log" 2>&1 &

	else
		$DIR/propeller -k $privKey &
	fi

else
	echo "Already running one instance propeller"
fi

exit 0
