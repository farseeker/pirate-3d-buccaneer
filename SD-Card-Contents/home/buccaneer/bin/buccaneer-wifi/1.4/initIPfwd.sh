#!/bin/bash

export HOME
case "$1" in
    start)
        if [ "$#" != 2 ]; then
                echo 'Usage: "Path to initIPfwd.sh" {start "interface"|stop}'
                exit 1
        fi

        ip_fwd=$(sysctl net.ipv4.ip_forward)
        ip_fwd=${ip_fwd:(-1)}

        if [ "$ip_fwd" == '0' ]; then
                echo "Connecting to Internet in Access Point"
                #Enable NAT
                iptables --flush
                iptables --table nat --flush
                iptables --delete-chain
                iptables --table nat --delete-chain
                iptables --table nat --append POSTROUTING --out-interface $2 -j MASQUERADE
                iptables --append FORWARD --in-interface wlan0 -j ACCEPT

                #Thanks to lorenzo
                #Uncomment the line below if facing problems while sharing PPPoE, see lorenzo's comment for $
                #iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

                sysctl -w net.ipv4.ip_forward=1

        else
                echo "IP Forwarding already ON"
        fi
    ;;
    stop)
        ip_fwd=$(sysctl net.ipv4.ip_forward)
        ip_fwd=${ip_fwd:(-1)}

        if [ "$ip_fwd" == '1' ]; then
                echo "Disconnecting to Internet in Access Point"
                sysctl -w net.ipv4.ip_forward=0

        else
                echo "IP forwarding already OFF"
        fi
    ;;
    *)
        echo 'Usage: "Path to initIPfwd.sh" {start "interface"|stop}'
        exit 1
    ;;
esac
exit 0

