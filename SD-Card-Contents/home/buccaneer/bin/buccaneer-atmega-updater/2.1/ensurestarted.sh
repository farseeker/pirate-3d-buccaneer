#! /bin/sh

#Function to read memory
readmemory()
{
	python2 memAccess_new.py $propellerPID | strings | grep -ao -E 'OK:[0-9]+' | cut -d':' -f2 | sort -n | uniq
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR

#If the log file for flashing is not found
flashfile=Flash.log

#Get the propeller PID
propellerPID=$(ps -ef | grep [p]ropeller | grep -ao -E '[0-9]+' | head -1)

#Check if the process has already run
ver=$(readlink $(pwd) | rev | cut -d'/' -f1 | rev)

if [ ! -f /tmp/flasher_"$ver"_already_run ]; then
	touch /tmp/flasher_"$ver"_already_run
	if [ ! -f $flashfile ]; then
	#Check if the printer is printing(memory usage), if so skip update, else flash the firmware & restart software
		r1=$(readmemory)
		echo "$r1" > /tmp/flashread1
		printFlag=1
		sleep 60
		while [ $printFlag -eq 1 ]; do
			r2=$(readmemory)
			echo "$r2" > /tmp/flashread2
			d=$(diff /tmp/flashread1 /tmp/flashread2)
			if [ "$d" == "" ]; then
				printFlag=0
			else
				printFlag=1
			fi
			mv /tmp/flashread2 /tmp/flashread1
			if [ $printFlag -eq 1 ]; then
				sleep 300 # if we are printing, don't disturb the memory
			fi
		done

		#Export the GPIO Pins of cubieboard to initiate SPI connection
		for i in 1 3 4 6 ; do echo $i > /sys/class/gpio/export ; done 2> /var/log/ATmegaFlasher.log &&
		echo out > /sys/class/gpio/gpio1_pd0/direction &&
		echo out > /sys/class/gpio/gpio4_pd1/direction &&
		echo out > /sys/class/gpio/gpio6_pd3/direction &&

		echo "GPIOs are exported." >> /var/log/ATmegaFlasher.log

		#Compile if there is no *.out file
		if [ ! -r ATmegaFlasher.out ] ; then

			gcc ATmegaFlasher.c -o ATmegaFlasher.out
			echo "Compiled"
		fi
		# Check the execution permission!!
		if [ ! -x ATmegaFlasher.out ] ; then
			chmod 755 ATmegaFlasher.out
		fi
		#Flash ATmega1284P
		atmegaflasher_running=$(ps -fe | grep ATmegaFlasher.out | grep -v grep)
		while [ "$atmegaflasher_running" != "" ]; do
			sleep 5
			atmegaflasher_running=$(ps -fe | grep ATmegaFlasher.out | grep -v grep)
		done
		./ATmegaFlasher.out ATmega.hex 2>> /var/log/ATmegaFlasher.log &&

		(d=$(date) 2>> /var/log/ATmegaFlasher.log ; echo "$d: ATmega Flashed" >> /var/log/ATmegaFlasher.log) &&

		#Create log file for flash completion
		echo "$d: ATmega Flashed" > $flashfile &&

		#Restart Software Stack
		killall /home/buccaneer/bin/buccaneer-propeller/current/propeller
	else
		echo "Firmware already flashed"
		exit 1
	fi
else
	echo "Already running an instance of ATmega Flasher"
fi
