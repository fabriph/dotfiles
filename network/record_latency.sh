# Usage:
#    $ ./record_latency.sh

logs_file="logs.tmp"
logs_csv="logs.csv"


record_latency_fn () {
	hostname="google.com"
	ip_address="142.250.65.238"
	sleep_time=10
	while :
	do
		echo
		echo
		echo
		date_time_field=`date "+%F %T"`
		timezone_field=`date "+%Z"`
		echo "$date_time_field ($timezone_field)"
		#ip_address=`dig +short $hostname | awk '{ print ; exit }'`
		# echo "$hostname resolved to $ip_address"
		# echo
		echo "****************************************************"
		ping "$ip_address" -c 5
		if [ $? -eq 0 ]; then
			ping_field="ok"
			echo "ping google IP  ::ok"
		else
			ping_field="failed"
			echo "ping google IP  ::bad"
		fi
		echo "sleeping 1 second"
		sleep 1

		echo "****************************************************"
		echo "DNS to google.com"
		if ping -q -c 3 -W 1 google.com >/dev/null; then
			echo "The network is up  ::ok"
			dns_field="ok"
		else
			echo "The network is down  ::bad"
			dns_field="failed"
		fi
		echo "sleeping 1 second"
		sleep 1

		echo "****************************************************"
		echo "curl to google.com"
		case "$(curl -s --max-time 2 -I http://google.com | sed 's/^[^ ]*  *\([0-9]\).*/\1/; 1q')" in
			[23])
				echo "HTTP connectivity is up  ::ok"
				curl_field="ok"
			;;
			5)
				echo "The web proxy won't let us through  ::bad"
				curl_field="bad_proxy"
			;;
			*)
				echo "The network is down or very slow  ::bad"
				curl_field="bad"
			;;
		esac

		echo "$date_time_field,$timezone_field,$ping_field,$dns_field,$curl_field" >> "$logs_csv"

		echo "sleeping $sleep_time seconds"
		sleep $sleep_time
		echo "****************************************************"
		echo "****************************************************"
		echo "****************************************************"
		echo "****************************************************"

	done
}

if [[ ! -e "$logs_csv" ]]; then
    touch "$logs_csv"
    echo "date time,timezone,ping,dns,curl" >> "$logs_csv"
fi
record_latency_fn 192.168.1.1 2>&1 | tee -a "$logs_file"
