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
	cp ./sources/placement-api.conf ./$hostname/
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	sed -i "s/HOSTIP/$ip/" "./$hostname/placement-api.conf"
done
