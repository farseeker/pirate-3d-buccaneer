DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd $DIR
ver=$(echo $(pwd) | rev | cut -d'/' -f1 | rev)

if [ ! -f /tmp/mech_"$ver"_files_checked ]; then

	df=$(diff /home/buccaneer/bin/mechanical-version/current/InitializePrinter /usr/bin/InitializePrinter)
	if [ "$df" != "" ]; then
		cp /home/buccaneer/bin/mechanical-version/current/InitializePrinter /usr/bin/InitializePrinter
	fi

	df=$(diff /home/buccaneer/bin/mechanical-version/current/ReadID /usr/bin/ReadID)
	if [ "$df" != "" ]; then
		cp /home/buccaneer/bin/mechanical-version/current/ReadID /usr/bin/ReadID
		chmod +x /usr/bin/ReadID
	fi

	touch /tmp/mech_"$ver"_files_checked
fi
