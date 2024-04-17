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
	cp ./sources/50-server.cnf ./$hostname/
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	sed -i "s/HOSTIP/$ip/" "./$hostname/50-server.cnf"
done

for host_info in "${hosts[@]}"; do
	ip="${host_info#*=}"
	hostname="${host_info%%=*}"
	IFS=,
	string="gcomm://${hosts[@]#*=}?gmcast.listen_addr=tcp://$ip"
	sed -i "s@WSREPCLUSTERADDRESS@$string@" "./$hostname/50-server.cnf"
done
