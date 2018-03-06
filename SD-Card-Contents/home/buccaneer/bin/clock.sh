#!/bin/bash

# This has to be launched at startup, as root, for example by putting it in
# /usr/bin/InitializePrinter, like
#
# bash clock.sh &
#
# MAKE SURE /usr/bin/InitializePrinter IS STILL LAUNCHED AS ROOT
# And remember that, as July 2014, buccaneer user is not in the sudoers.


disk_save_delay=300			# Save date every 300 seconds = 5 minutes
clock_saved_file=/var/clock_storage	# The file where the date is stored on disk
NTP_server="pool.ntp.org"		# One of the most popular NTP server in the Linux world

if [ -r $clock_saved_file ]; then
	d=$(cat $clock_saved_file)
	date -s "$d"
	# time updated from last saved time
fi

sleep 60
ntp_ok=0
ntpdate "$NTP_server" && ntp_ok=1

while [ TRUE ]; do
	if [ $ntp_ok -eq 0 ]; then
		ntpdate "$NTP_server" && ntp_ok=1
		# time updated from NTP server
	fi
	date > $clock_saved_file
	sleep $disk_save_delay
done

