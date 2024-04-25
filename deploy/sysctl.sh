#!/bin/bash

source hosts.conf
declare -a hosts

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done

for host_info in "${hosts[@]}"; do
        ip="${host_info#*=}"
	hostname="${host_info%%=*}"
	if [[ "$ip" != "$myip" ]]; then
		scp -o "StrictHostKeyChecking no" ./$hostname/98-custom.conf root@$hostname:/etc/sysctl.d/
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'sysctl -f /etc/sysctl.d/98-custom.conf'";
	fi
done

