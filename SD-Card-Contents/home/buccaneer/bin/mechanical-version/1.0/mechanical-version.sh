if [ -z $1 ]; then
	echo "mechanical-version.sh : Give as first argument the mechanical version number" > /dev/stderr
	exit
fi

result=$(grep -E "^$1:" /home/buccaneer/bin/mechanical-version/current/version.txt)

if [ "$result" == "" ]; then
	# Default prudential settings
	echo "printing-X-range=130:printing-Y-range=96:printing-Z-range=139" | tr ':' '\n'
else
	echo "$result" | cut -d':' -f1 --complement | tr ':' '\n'
fi
