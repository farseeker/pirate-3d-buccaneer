#!/usr/bin/env python2

import subprocess
import os
import sys
import time

def isConnected():
#Start
	connectionState = 2
	if not (ping()):
		return connectionState

		
	kwargs = {}
	cmdlist = ['ip','route','ls']
	
	selfprocess = subprocess.Popen(cmdlist, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	
	inEth = False
	inWifi = False
	isEthUp = False
	isWifiUp = False

	while len(line):
		#print(line)
		if ('eth0' in line):
			isEthUp = True

		if ('wlan1' in line):
			isWifiUp = True
				
		line = selfprocess.stdout.readline()


	if (isEthUp and isWifiUp):
		return 3
	elif (isEthUp):
		return 0
	elif (isWifiUp):
		return 1
	else:
		return 2

	#return connectionState
#End

def ping():
#Start
	kwargs = {}
	cmdlist = ['ping', '-c', '5', "8.8.8.8"]

	selfprocess = subprocess.Popen(cmdlist, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	connected = False

	while len(line):
		#print(line)
		if ('unknown host' in line):
			break
		if ('5 packets transmitted, 5 received' in line):
			connected = True
			break
		line = selfprocess.stdout.readline()
	return connected
#End


def getWifiName():
#Start
	wifiNameFile = r'/etc/wpa_supplicant/wpa_supplicant.conf'
	fp = open(wifiNameFile, 'r')
	fp_lines = fp.read().split('\n')
	wifiName = ''
	for line in fp_lines:
		if ('ssid' in line):
			wifiName = line.split('=')[1][1:-1]
			return wifiName
	return
#End


def getWifiPasswd():
#Start
	wifiNameFile = r'/etc/wpa_supplicant/wpa_supplicant.conf'
	fp = open(wifiNameFile, 'r')
	fp_lines = fp.read().split('\n')
	wifiPasswd = ''
	for line in fp_lines:
		if ('#psk' in line):
			wifiPasswd = line.split('=')[1][1:-1]
			return wifiPasswd
	return
#End


def connectWifi(wifiName, passwd):
#Start
### return 0: Already connected through Ethernet
### return 1: Successfully connected to wifi: <wifiName>
### return 2: Connection failed. Try again.
### return 3: Connected to both wifi and ethernet

	connectionState = isConnected()

	if (connectionState == 1) or (connectionState == 3):
		oldWifiName = getWifiName()
		oldWifiPasswd = getWifiPasswd()

		if ((wifiName == oldWifiName) and (passwd == oldWifiPasswd)):
			return 1

		
	cmd_setNamePasswd = r'wpa_passphrase "%s" "%s" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null' % (wifiName, passwd)
	#print("cmd = %s" % (cmd_setNamePasswd))
	os.system(cmd_setNamePasswd)

	return startWifi()

#End


def isWifiRunning():
#Start
	isWifiRunning = False

	kwargs = {}
        cmdlist = ['ip','route','ls']
		
	selfprocess = subprocess.Popen(cmdlist, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	#print(line)

	while len(line):
		if ('wlan1' in line):
			isWifiRunning = True
		line = selfprocess.stdout.readline()

	return isWifiRunning		
#End



def startWifi():
#Start
	#print('Connecting...')

	stopWifi()

	kwargs = {}

        currentPath = os.path.dirname(os.path.realpath(__file__))
	cmd_start = ['sudo', 'sh', currentPath + '/initWifi.sh', 'start']
	#print cmd_start

	selfprocess = subprocess.Popen(cmd_start, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	#print(line)
        while len(line):
		#print(line)
                line = selfprocess.stdout.readline()	
	
	return isConnected()
#End


def startSavedWifi():
#Start
	connectionStatus = isConnected()
	
	if ((connectionStatus == 3) or (connectionStatus == 1)):
		return connectionStatus

	return (startWifi())
#End


def stopWifi():
#Start
	kwargs = {}

        currentPath = os.path.dirname(os.path.realpath(__file__))
	cmd_stop = ['sudo', 'sh', currentPath + '/initWifi.sh', 'stop']

	#print cmd_stop

	selfprocess = subprocess.Popen(cmd_stop, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	while len(line):
		line = selfprocess.stdout.readline()

	selfprocess = subprocess.Popen(cmd_stop, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)
	
	line = selfprocess.stdout.readline()
	while len(line):
		line = selfprocess.stdout.readline()

#Stop


def getWifiList():
#Start
	#print(isWifiRunning())
	if not (isWifiRunning()):
		#print("Entering if to start wifi")
		kwargs = {}
		cmd_wifi_up = ['sudo', 'ip', 'link', 'set', 'dev', 'wlan1', 'up']

		selfprocess = subprocess.Popen(cmd_wifi_up, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

		line = selfprocess.stdout.readline()
		while len(line):
			line = selfprocess.stdout.readline()

	kwargs = {}
	cmd = ['cat', '/etc/hostapd/hostapd.conf']		
	selfprocess = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	APname = ""
        line = selfprocess.stdout.readline()
	while len(line):
		line=line.strip()
		#print line
		if ('ssid=' in line):
			APname=line[5:]
			break
        	line = selfprocess.stdout.readline()
	#print APname

	kwargs = {}
	cmdlist = ['sudo','iwlist','wlan1','scan']

	selfprocess = subprocess.Popen(cmdlist, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	wifiList = []
	#wifiNum = 1
	line = selfprocess.stdout.readline()
	while len(line):
		line = line.strip()
		if ('ESSID' in line):
			line = line.split(':')[1][1:-1]
			if (line == APname) or (line == ""):
				continue
			#print("line: %s" % (line))
			wifiList = wifiList + [line]
			#wifiNum = wifiNum + 1
			#print line
		#print('\n')
		line = selfprocess.stdout.readline()

	#print('\n\n')
	#print(wifiList)
	output_wifiList = "["
	for i in range(0,len(wifiList)-1):
		output_wifiList = output_wifiList + """"%s", """ % (wifiList[i])
	output_wifiList = output_wifiList + """"%s"]""" % (wifiList[-1])
	return output_wifiList
#End


def startAP():
#Start
	kwargs = {}

        currentPath = os.path.dirname(os.path.realpath(__file__))
	cmd_startAP = ['sudo', 'sh', currentPath + '/initAP.sh', 'start']
	
	selfprocess = subprocess.Popen(cmd_startAP, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	while len(line):
		line = selfprocess.stdout.readline()
#End


def stopAP():
#Start
	kwargs = {}

        currentPath = os.path.dirname(os.path.realpath(__file__))
	cmd_stopAP = ['sudo', 'sh', currentPath + '/initAP.sh', 'stop']

	selfprocess = subprocess.Popen(cmd_stopAP, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	while len(line):
		line = selfprocess.stdout.readline()
#End

def changeAPkey(type,key):
#Start
	if (type=="name"):
		cmd = r"sudo sed -i 's/^ssid=.*$/ssid=%s/' /etc/hostapd/hostapd.conf" % (key)

	elif (type=="passwd"):
		cmd = r"sudo sed -i 's/^wpa_passphrase=.*$/wpa_passphrase=%s/' /etc/hostapd/hostapd.conf" % (key)

        os.system(cmd)
#End

def changeAP(ssid=None,passphrase=None):
#Start	
	if (not ssid) and (not passphrase):
		return -1
	stopAP()
	time.sleep(2)

	if (ssid) and (passphrase):
		changeAPkey("name",ssid)
		changeAPkey("passwd",passphrase)
	elif (ssid) and (not passphrase):
		changeAPkey("name",ssid)
	elif (not ssid) and (passphrase):
		changeAPkey("passwd",passphrase)
		
	startAP()
	return 0
#End	
	
def startIPfwdAP():
#Start
	connectionStatus = isConnected()
	#print(connectionStatus)
	if (connectionStatus == 2):
		return False

	kwargs = {}

        currentPath = os.path.dirname(os.path.realpath(__file__))
	cmd_startIPforward = ['sudo', 'sh', currentPath + '/initIPfwd.sh', 'start']

	if (connectionStatus == 0):
		cmd_startIPforward = cmd_startIPforward + ['eth0']
	elif (connectionStatus == 1):
		cmd_startIPforward = cmd_startIPforward + ['wlan1']

	selfprocess = subprocess.Popen(cmd_startIPforward, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	while len(line):
		line = selfprocess.stdout.readline()

	return True
#End


def stopIPfwdAP():
#Start
	kwargs = {}

        currentPath = os.path.dirname(os.path.realpath(__file__))
	cmd_stopIPforward = ['sudo', 'sh', currentPath + '/initIPfwd.sh', 'stop']
	
	selfprocess = subprocess.Popen(cmd_stopIPforward, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

	line = selfprocess.stdout.readline()
	while len(line):
		line = selfprocess.stdout.readline()
#End

def help():
#Start
	print("Command						;Description\n")
	print("help						;Print this help menu")
	print("connect <wifiName> <passwd>			;Connect to wifi")
	print("isConnected					;Check if connected to internet and by which interface")
	print("scan						;Scan and give the list of wireless networks")
	print("connect						;Connects to last connected wifi")
	print("disconnect					;Disconnect to wifi")
	#print("startAP						;Start access point")
	#print("stopAP						;Stop access point")
	#print("startIPfwd					;Start IP forwarding through access point. Only works when connected to internet")
	#print("stopIPfwd					;Stop IP forwarding through access point")
	print("changeAP -name|-passwd <wifiName|passwd>	;To change wifi name or password of access point")
	print("changeAP -name <wifiName> -passwd <passwd>	;To change both wifi name and password of access point")
#End


def main():
#Start
	#print("List of arguments:")
	argumentList = sys.argv[1:]
	#print(argumentList)
	
	if (len(argumentList) == 1):
		if (argumentList[0] == 'isConnected'):
			connectionState = isConnected()
			if (connectionState == 0):
				print("Connected to Ethernet")
			elif (connectionState == 1):
				wifiName = getWifiName()
				print("Connected to wifi: %s" % (wifiName))
			elif (connectionState == 2):
				print("Not connected to internet")
			elif (connectionState == 3):
				print("Connected to both Ethernet and Wifi")
				
		elif (argumentList[0] == 'scan'):
			wifiList = getWifiList()
			print(wifiList)

		elif (argumentList[0] == 'connect'):
		
			connectionStatus = startSavedWifi()
			if (connectionStatus == 1) or (connectionStatus == 3):
				print("Connected to wifi: %s" % (getWifiName()))
			else:
				print("Failed to connect")

		elif (argumentList[0] == 'disconnect'):
			stopWifi()	
			print('Disconnected to Wifi')

		elif (argumentList[0] == 'startAP'):
			startAP()
			print('Starting as Access Point')

		elif (argumentList[0] == 'stopAP'):
			stopAP()
			print("Stopping as Access Point")

#		elif (argumentList[0] == 'startIPfwd'):
#			if(startIPfwdAP()):
#				print('Starting IP forwarding')
#			else:
#				print('Failed to start IP fwd. Connect to internet.')

#		elif (argumentList[0] == 'stopIPfwd'):
#			stopIPfwdAP()
#			print('Stopping IP forwarding')

		elif (argumentList[0] == 'help'):
			help()

		else:
			help()

	elif len(argumentList) == 3:
		if (argumentList[0] == 'connect'):
			wifiName = argumentList[1]
			wifiName = wifiName.replace('++',' ')
			#print(wifiName)
			passwd = argumentList[2]
			#print("wifiName = %s	passwd = %s" % (wifiName,passwd))
			connectionState = connectWifi(wifiName, passwd)
			if (connectionState == 1) or (connectionState == 3):
                                print("Connected to wifi: %s" % (getWifiName()))
                        else:
                                print("Failed to connect")

		elif (argumentList[0] == 'changeAP'):
			if (argumentList[1] == '-name'):
				changeAP(ssid=argumentList[2])
			elif (argumentList[1] == '-passwd'):
				changeAP(passphrase=argumentList[2])
			else:
				help()
		
		else:
			help()

	elif len(argumentList) == 5:
		if (argumentList[0] == 'changeAP'):
			if (argumentList[1] == '-name') and (argumentList[3] == '-passwd'):
                                changeAP(ssid=argumentList[2],passphrase=argumentList[4])
			elif (argumentList[1] == '-passwd') and (argumentList[3] == '-name'):
                                changeAP(ssid=argumentList[4],passphrase=argumentList[2])
			else:
				help()

		else:
			help()

	else:
		help()
#End

	
if __name__ == "__main__":
    main()
