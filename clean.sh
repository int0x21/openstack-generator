#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbancers

for var_name in ${!HOSTNAME_*}; do
	ip_var_name="HOSTIP${var_name#HOSTNAME}"
	host_entry="${!var_name}=${!ip_var_name}"
	hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

# Create directories
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	rm -rf "./$hostname"
done

