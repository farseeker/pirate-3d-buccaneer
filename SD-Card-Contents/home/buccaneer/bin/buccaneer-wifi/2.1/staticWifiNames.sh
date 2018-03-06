#!/bin/bash
tmpLock="/tmp/staticWifiNames.lock" # name according to bin/buccaneer-wifi/current/ensurestarted.sh and /usr/bin/InitializePrinter
echo "$$" > $tmpLock
