#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

for var_name in ${!HOSTNAME_*}; do
	ip_var_name="HOSTIP${var_name#HOSTNAME}"
	host_entry="${!var_name}=${!ip_var_name}"
	hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

# Create base file
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	cp ./sources/keepalived.conf ./$hostname/keepalived.conf
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	sed -i "s/HOST_IP/$ip/" "./$hostname/keepalived.conf"
done

i=100
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
	sed -i "s/PRIONR/$i/" "./$hostname/keepalived.conf"
	i=$((i-1))
done

for host_info in "${hosts[@]}"; do
	ip="${host_info#*=}"
	hostname="${host_info%%=*}"
	for peer_ip in "${hosts[@]}"; do
		pip="${peer_ip#*=}"
		if [[ "$pip" != "$ip" ]]; then 
			sed -i "/unicast_peer {/a \               \ $pip" "./$hostname/keepalived.conf"
		fi
	done
done

for host_info in "${hosts[@]}"; do
	lbip="${loadbalancers#*=}"
	hostname="${host_info%%=*}"
	sed -i "/virtual_ipaddress {/a \               \ $lbip" "./$hostname/keepalived.conf"
done

for host_info in "${hosts[0]}"; do
	hostname="${host_info%%=*}"
	sed -i "s/BACKUP/MASTER/" "./$hostname/keepalived.conf"
done
