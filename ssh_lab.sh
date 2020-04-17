#!/bin/bash

func(){
	echo ">> Sending ping to 155.210.154.208"
	if ping -c 1 155.210.154.208 &>/dev/null; then
		echo ">> Host up"
		echo ">> Opening ssh connection"
		konsole -e "ssh -X a757024@155.210.154.208" &>/dev/null
	else
		echo ">> Host down"
		echo ">> Establish connection with central"
		ssh a757024@central.cps.unizar.es /usr/local/etc/wakeonlan 00:10:18:80:67:84
		for x in {1..65} ; do
			sleep 1
			printf .
		done | pv -pt -i0.2 -s65 -w 80 > /dev/null
		func
	fi
}

func

exit 0
