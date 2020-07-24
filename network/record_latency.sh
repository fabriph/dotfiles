#!/usr/bin/bash
# Usage:
#    $ ./record_latency.sh 192.168.1.1 2>&1 | tee -a logs.tmp

while :
do
	echo
	date
	ping "$1" -c 10
	sleep 1
done

