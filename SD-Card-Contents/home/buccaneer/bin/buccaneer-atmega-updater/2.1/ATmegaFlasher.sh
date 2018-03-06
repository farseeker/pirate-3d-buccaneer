#!/bin/bash
for i in 1 3 4 6 ; do echo $i > /sys/class/gpio/export ; done 2> /var/log/ATmegaFlasher.log
echo out > /sys/class/gpio/gpio1_pd0/direction 2>> /var/log/ATmegaFlasher.log
echo out > /sys/class/gpio/gpio4_pd1/direction 2>> /var/log/ATmegaFlasher.log
echo out > /sys/class/gpio/gpio6_pd3/direction 2>> /var/log/ATmegaFlasher.log

cd /home/buccaneer/debug/flashFirmware/

#To compile if there is no *.out file
if [ ! -r ATmegaFlasher.out ] ; then
        gcc ATmegaFlasher.c -o ATmegaFlasher.out 2>> /var/log/ATmegaFlasher.log
fi

#./ATmegaFlasher.out ATmega.hex 2>> /var/log/ATmegaFlasher.log
#d=$(date) 2>> /var/log/ATmegaFlasher.log
#echo "$d: ATmega Flashed" 2>> /var/log/ATmegaFlasher.log
